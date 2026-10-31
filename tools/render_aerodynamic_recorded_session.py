from pathlib import Path
import argparse,json,wave,zipfile
import numpy as np

ROOT=Path(__file__).resolve().parent.parent
parser=argparse.ArgumentParser(description="Render the selected recorded-guitar Aerodynamic session mix.")
parser.add_argument('--repo-root',type=Path,default=ROOT)
parser.add_argument('--assets-dir',type=Path)
parser.add_argument('--output-dir',type=Path)
args=parser.parse_args()
ROOT=args.repo_root.resolve()
ASSETS=(args.assets_dir or ROOT/'tracks/aerodynamic/references/local_samples/recorded_session').resolve()
OUT=(args.output_dir or ROOT/'renders/aerodynamic_recorded_session').resolve()
OUT.mkdir(parents=True,exist_ok=True)
from recorded_guitar_audio import read_wav,resample_pitch
SR=48000;DURATION=210;N=SR*DURATION
REPO=ROOT
STEMS=REPO/'renders/aerodynamic_v10'
offset=0.438  # Measured common start offset of the existing V10 stem exports.
lead_settings={'drive_db': 32, 'hardness': 5, 'ceiling_db': -12, 'cabinet': 'Marshall JCM800 - Marshall Stock 70.wav', 'delay_ms': 121.95121951219512, 'delay_feedback_db': -14, 'delay_wet_db': -18}

def rms(a):return float(np.sqrt(np.mean(a.astype(np.float64)**2)))
def sl(start,end):return slice(round(start*SR),round(end*SR))

def load(path,start=0,duration=None):
    with wave.open(str(path)) as w:
        sr=w.getframerate();ch=w.getnchannels();assert w.getsampwidth()==3
        w.setpos(round(start*sr))
        raw=w.readframes(round(duration*sr) if duration else w.getnframes()-w.tell())
    b=np.frombuffer(raw,dtype=np.uint8).reshape(-1,3)
    v=b[:,0].astype(np.int32)|(b[:,1].astype(np.int32)<<8)|(b[:,2].astype(np.int32)<<16)
    a=(((v^8388608)-8388608).astype(np.float32)/8388608).reshape(-1,ch)
    return a,sr

def load_stem(name):
    a,sr=load(STEMS/f'aerodynamic_v10_{name}.wav',offset)
    assert sr==SR
    if len(a)<N:a=np.pad(a,((0,N-len(a)),(0,0)))
    return a[:N]

def save(path,a):
    assert a.shape==(N,2) and np.isfinite(a).all() and abs(a).max()<.99
    # Chunked output avoids a full-size interleaved integer copy.
    with wave.open(str(path),'wb') as w:
        w.setnchannels(2);w.setsampwidth(3);w.setframerate(SR)
        for start in range(0,N,SR*5):
            v=np.rint(a[start:start+SR*5].reshape(-1)*8388608).astype(np.int32)
            b=np.stack([v&255,(v>>8)&255,(v>>16)&255],axis=1).astype(np.uint8)
            w.writeframesraw(b.tobytes())

print('Loading the existing full-length stems.',flush=True)
original_lead=load_stem('lead');original_melody=load_stem('melody');original_bass=load_stem('bass')
drums=load_stem('drums');harmony=load_stem('harmony');fx=load_stem('fx')

# Main lead: exactly the V10 corrected mixed-register motifs, through selected A.
# Preserve 2:10–2:12 unchanged: its lead stem also contains embedded transition
# percussion, bass and pluck stutters, so replacing that composite would lose them.
lower=[[62,54,59,54],[62,56,59,56],[67,59,64,59],[64,57,61,57]]
upper=[[62,66,59,66],[62,68,59,68],[67,59,64,59],[64,57,61,57]]
lead_events=[];bass_events=[];melody_schedule=[]
def add_bass(song_time,source_bar,base_amp,sub_amp=0):
    if source_bar%2==0:
        hits=[(0,1,47,1,.70),(1.5,.5,47,1,.82),(3.5,.5,42,1,.82)]
    else:
        b=.66 if (source_bar//2)%2==0 else 1
        e=1 if (source_bar//2)%2==0 else .66
        hits=[(0,1,43,1,.70),(1.5,.5,47,b,.68),(1.5,.5,40,e,.68),(3.5,.5,42,1,.82)]
    for onset,duration,midi,level,sublevel in hits:
        bass_events.append(dict(onset=song_time+onset*.5,midi=midi,beats=duration,
            level=level,amp=base_amp,sub_amp=sub_amp,sublevel=sublevel))

for bar in range(33):
    time=64+bar*2
    if bar<12:
        local=bar;phrase=local%4;motif=(lower if local<8 else upper)[phrase];effect=False
    elif bar<18:
        local=bar-12;phrase=local%4;motif=upper[phrase];effect=local==4
        melody_schedule.append((time,phrase,'under-lead'))
        add_bass(time,local%4,.220 if local<4 else .230,.030 if local>=4 else 0)
    else:
        local=bar-18;phrase=local%4;motif=lower[phrase];effect=local in [5,7,12,14]
        if local not in [8,9]:melody_schedule.append((time,phrase,'under-lead'))
        amp=.235 if local<8 else (.215 if local<12 else .245)
        sub=(2<=local<8) or (12<=local<15)
        add_bass(time,4+local%8,amp,.030 if sub else 0)
    for j,midi in enumerate(motif*4):lead_events.append((time+j*.125,midi,1.))
    if effect:
        for j,midi in enumerate(lower[phrase]*4):lead_events.append((time+j*.125,midi,.10/.48))

# Opening groove, subtraction, and callback. The truncated final bar stays as
# originally rendered, preserving its deliberate silence before the lead/ending.
for bar in range(23):
    time=16+bar*2
    melody_schedule.append((time,bar%4,'front'))
    if bar<4:amp=.235
    elif bar<8:amp=.245
    elif bar<16:amp=.255
    elif bar<20:amp=.265
    else:amp=[.245,.235,.225][bar-20]
    sub=.045 if (4<=bar<20 or bar==20) else 0
    add_bass(time,bar%4,amp,sub)
for bar in range(3):
    time=198+bar*2
    melody_schedule.append((time,bar,'front'))
    add_bass(time,4+bar,[.225,.220,.205][bar])

# Post-bell bass pedal: unchanged F-sharp2 notes and onset grid, with new tone.
for bar in range(16):
    time=162+bar*2
    for onset,beats,level,sublevel in [(0,1,1,.72),(1.5,.25,.9,.82),(1.75,.25,.9,.82)]:
        bass_events.append(dict(onset=time+onset*.5,midi=42,beats=beats,level=level,
            amp=.24/.88,sub_amp=.035 if bar in [12,14] else 0,sublevel=sublevel))

print('Rendering the selected lead across its complete main passage.',flush=True)
sample,native_sr=read_wav(ASSETS/'samples/guitar_E4.wav')
first=int(np.flatnonzero(abs(sample)>.005)[0]);sample=sample[max(0,first-int(.001*native_sr)):]
dry=np.zeros(66*native_sr);cache={}
for time,midi,level in lead_events:
    if midi not in cache:
        rate=2**((midi-64)/12);length=int(.125*.82*native_sr)
        a=resample_pitch(sample[:int(length*rate)+128],rate)[:length].copy()
        attack=int(.001*native_sr);release=int(.015*native_sr)
        a[:attack]*=np.linspace(0,1,attack)
        a[-release:]*=.5+.5*np.cos(np.linspace(0,np.pi,release));cache[midi]=a
    a=cache[midi]*level;s=round((time-64)*native_sr);dry[s:s+len(a)]+=a
a=dry*2**(lead_settings['drive_db']/6);limit=2**(lead_settings['ceiling_db']/6)
excess=np.maximum(abs(a)-limit,0)
a=np.where(abs(a)>limit,np.sign(a)*(limit+excess/(2**lead_settings['hardness']+excess)),a)
cab=Path.home()/'Library/Application Support/REAPER/Data/amp_models'/lead_settings['cabinet']
with wave.open(str(cab)) as w:
    assert w.getframerate()==native_sr
    ir=np.frombuffer(w.readframes(w.getnframes()),dtype='<i2').reshape(-1,2)/32768.
wet=np.stack([np.convolve(a,ir[:,c])[:len(dry)] for c in range(2)],axis=1)
delay=round(lead_settings['delay_ms']*.001*native_sr);direct=wet.copy()
for k in range(1,8):
    off=k*delay
    wet[off:]+=direct[:-off]*2**(lead_settings['delay_wet_db']/6)*(2**(lead_settings['delay_feedback_db']/6))**(k-1)
wet=np.stack([resample_pitch(wet[:,c],native_sr/SR)[:66*SR] for c in range(2)],axis=1).astype(np.float32)
lead=original_lead.copy()
scales={}
for start,end in [(64,88),(88,100),(100,116),(116,120),(120,130)]:
    local=slice((start-64)*SR,(end-64)*SR)
    gain=rms(original_lead[sl(start,end)])/rms(wet[local])*10**(-2/20)
    lead[sl(start,end)]=wet[local]*gain;scales[f'{start}-{end}']=gain
# Crossfade the final 15 ms into the preserved transition composite.
cross=round(.015*SR);join=130*SR
blend=np.linspace(0,1,cross,dtype=np.float32)[:,None]
lead[join-cross:join]=(1-blend)*lead[join-cross:join]+blend*original_lead[join-cross:join]
del wet,dry,direct,a

print('Placing the wah phrases and rounder bass, retaining transition omissions.',flush=True)
phrase,sr=load(ASSETS/'wah-melody.wav')
assert sr==SR and phrase.shape==(8*SR,2)
wah=original_melody.copy()
front_gain=rms(original_melody[sl(16,24)])/rms(phrase)
under_gain=rms(original_melody[sl(88,96)])/rms(phrase)*10**(10/20)
for time,position,context in melody_schedule:
    gain=front_gain if context=='front' else under_gain
    wah[sl(time,time+2)]=phrase[position*2*SR:(position+1)*2*SR]*gain

bass_mono=np.zeros(N,dtype=np.float32)
for e in bass_events:
    length=round((e['beats']*.5*.82+.005)*SR);t=np.arange(length)/SR
    phase=2*np.pi*(440*2**((e['midi']-69)/12))*t
    harmonics=(.24*np.sin(2*phase)+.10*np.sin(3*phase)+.045*np.sin(4*phase))*np.exp(-t/.12)
    note=np.tanh((np.sin(phase)+harmonics)*1.25)/1.25
    env=(1-np.exp(-t/.0025))*(.55+.45*np.exp(-t/.065))
    release=min(round(.036*SR),length//3)
    env[-release:]*=.5+.5*np.cos(np.linspace(0,np.pi,release))
    note*=env*e['level']*(e['amp']/.220)
    if e['sub_amp']:
        note+=np.sin(phase)*(1-np.exp(-t/.005))*np.linspace(1,0,length)*e['sublevel']*(e['sub_amp']/(.220*.88))
    start=round(e['onset']*SR);bass_mono[start:start+length]+=note.astype(np.float32)
bass_gain=rms(original_bass[sl(88,96)])/rms(bass_mono[sl(88,96)])
bass=original_bass.copy()
for start,end in [(16,62),(88,130),(162,194),(198,204)]:
    bass[sl(start,end)]=bass_mono[sl(start,end),None]*bass_gain
del bass_mono

# Structural checks compare protected areas against the original components.
checks=dict(isolated_lead_has_no_added_bass=np.array_equal(bass[sl(64,88)],original_bass[sl(64,88)]),
    isolated_lead_has_no_added_wah=np.array_equal(wah[sl(64,88)],original_melody[sl(64,88)]),
    half_time_melody_omission_preserved=np.array_equal(wah[sl(116,120)],original_melody[sl(116,120)]),
    transition_composite_preserved=np.array_equal(lead[sl(130,132)],original_lead[sl(130,132)]),
    pre_lead_silence_preserved=np.array_equal(wah[sl(63.5,64)],original_melody[sl(63.5,64)]) and np.array_equal(bass[sl(63.5,64)],original_bass[sl(63.5,64)]),
    ending_preserved=np.array_equal(wah[sl(204,210)],original_melody[sl(204,210)]) and np.array_equal(bass[sl(204,210)],original_bass[sl(204,210)]))
assert all(checks.values()),checks

mix=drums+harmony+fx+lead+wah+bass
assert np.isfinite(mix).all()
master_gain=.80/float(abs(mix).max())
mix*=master_gain
# Original tails are retained; zero padding after the source runs out closes cleanly.
mix[-960:]*=np.linspace(1,0,960,dtype=np.float32)[:,None]
save(OUT/'Aerodynamic-session-mix.wav',mix)
print('Stereo mix written; exporting aligned stems and project.',flush=True)

tracks=[('drums','Drums - original',drums),('bass','Rounder bass',bass),('lead','Lead A',lead),
        ('wah-melody','Wah funk melody',wah),('harmony','Harmony - original',harmony),('fx','Bells and FX - original',fx)]
for filename,title,a in tracks:
    a*=master_gain
    a[-960:]*=np.linspace(1,0,960,dtype=np.float32)[:,None]
    save(OUT/(filename+'.wav'),a)

rpp=['<REAPER_PROJECT 0.1 7.79 1','  TEMPO 120','  SAMPLERATE 48000','  MASTER_VOLUME 1']
markers=[(0,'Opening bells'),(16,'Opening groove - wah and round bass'),(64,'Isolated lead A'),
    (88,'Groove returns'),(100,'Fuller groove'),(116,'Half-time - wah drops out'),(124,'Climax'),
    (130,'Preserved transition stutter'),(132,'Transition bell'),(138,'Post-bell melody'),
    (162,'Post-bell rhythm'),(194,'Sparse exit'),(198,'Opening callback'),(206,'Final decay'),(208,'Arrangement end')]
for i,(position,title) in enumerate(markers,1):rpp.append(f'  MARKER {i} {position} "{title}"')
for filename,title,_ in tracks:
    rpp+=['  <TRACK',f'    NAME "{title}"','    VOLPAN 1 0','    MAINSEND 1 0','    REC 0 0 0 0',
        '    <ITEM','      POSITION 0',f'      LENGTH {DURATION}',f'      NAME "{title}"','      VOLPAN 1 0 1 -1','      SOFFS 0',
        '      <SOURCE WAVE',f'        FILE "{filename}.wav"','      >','    >','  >']
rpp+=['>']
(OUT/'Aerodynamic Session Wrap.rpp').write_text('\n'.join(rpp)+'\n')

# Verify the delivered WAV, its final silence, and the sum of quantized stems.
with wave.open(str(OUT/'Aerodynamic-session-mix.wav')) as w:
    assert (w.getframerate(),w.getnchannels(),w.getsampwidth(),w.getnframes())==(SR,2,3,N)
    w.setpos(N-SR//10);tail=w.readframes(SR//10)
    assert not any(tail)
stem_sum=np.zeros_like(mix)
for filename,_,_ in tracks:
    a,_=load(OUT/(filename+'.wav'));stem_sum+=a
error=float(abs(stem_sum-mix).max())
assert error<2e-6,error
checks.update(duration_seconds=DURATION,arrangement_seconds=208,sample_rate=SR,bit_depth=24,
    channels=2,sample_peak_dbfs=float(20*np.log10(abs(mix).max())),
    final_100_ms_silent=True,maximum_stem_sum_error=error)
manifest=dict(title='Aerodynamic - session wrap',base='V10 rendered stems, aligned by the existing 0.438-second recording offset',
    selections=dict(lead='A',funk_melody='Wah guitar',bass='Rounder bass'),
    level_policy='Selected -2 dB lead and +10 dB under-lead wah. Opening wah matched to foreground melody. One global peak-headroom gain; no section master normalization or limiter.',
    preserved='Original drum, harmony, bell and FX stems; post-bell synth voices; composite 2:10 transition stutter; truncated lead-entry/callback bars and final decay.',
    editable='Six aligned rendered tracks with independent volume/pan in the REAPER project; processing is printed to audio.',
    original_project_unchanged=True,lead_section_gains=scales,front_wah_gain=front_gain,under_lead_wah_gain=under_gain,
    bass_gain=bass_gain,master_gain=master_gain,melody_schedule=melody_schedule,bass_events=bass_events,checks=checks)
(OUT/'manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')

# A compact handoff file opens the self-contained project folder after extraction.
package=OUT/'Aerodynamic-session-wrap.zip'
with zipfile.ZipFile(package,'w',zipfile.ZIP_DEFLATED,compresslevel=3) as z:
    for path in [OUT/'Aerodynamic Session Wrap.rpp',OUT/'Aerodynamic-session-mix.wav',OUT/'manifest.json']+[OUT/(name+'.wav') for name,_,_ in tracks]:
        z.write(path,'Aerodynamic-session-wrap/'+path.name)
print(json.dumps(checks,indent=2),flush=True)
print('Created:',package,flush=True)
