const audio = document.querySelector('#audio');
const play = document.querySelector('#play');
const mute = document.querySelector('#mute');
const volume = document.querySelector('#volume');
const seek = document.querySelector('#seek');
const current = document.querySelector('#current-time');
const duration = document.querySelector('#duration');
const title = document.querySelector('#track-title');
const subtitle = document.querySelector('#track-subtitle');

const formatTime = (seconds) => `${Math.floor(seconds / 60)}:${String(Math.floor(seconds % 60)).padStart(2, '0')}`;
const setPlaying = () => { play.textContent = audio.paused ? '▶' : 'Ⅱ'; play.setAttribute('aria-label', audio.paused ? 'Play' : 'Pause'); };

play.addEventListener('click', () => audio.paused ? audio.play() : audio.pause());
audio.addEventListener('play', setPlaying);
audio.addEventListener('pause', setPlaying);
audio.addEventListener('loadedmetadata', () => { duration.textContent = formatTime(audio.duration); });
audio.addEventListener('timeupdate', () => { current.textContent = formatTime(audio.currentTime); seek.value = audio.duration ? (audio.currentTime / audio.duration) * 100 : 0; });
seek.addEventListener('input', () => { if (audio.duration) audio.currentTime = (seek.value / 100) * audio.duration; });
volume.addEventListener('input', () => { audio.volume = volume.value; audio.muted = false; mute.textContent = '⌕'; });
mute.addEventListener('click', () => { audio.muted = !audio.muted; mute.textContent = audio.muted ? '×' : '⌕'; });
document.querySelectorAll('.track-row').forEach((row) => row.addEventListener('click', () => {
  document.querySelectorAll('.track-row').forEach((item) => item.classList.remove('is-active'));
  row.classList.add('is-active'); audio.src = row.dataset.src; title.textContent = row.dataset.title; subtitle.textContent = row.dataset.subtitle; audio.play();
}));
audio.volume = volume.value;
