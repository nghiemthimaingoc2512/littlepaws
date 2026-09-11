// Memories: a short list of moments, newest first.
import { el, card, text, roundButton } from '../ui.js'
import { petNode } from '../art.js'

export function MemoriesScreen({ go, game }) {
  const memories = game.memories()
  const entry = (memory) => card([
    el('div', { class: 'memory' }, [
      petNode(memory.art, 'art pet-portrait'),
      el('div', { class: 'grow' }, [
        el('h3', { text: memory.title }),
        text(memory.text),
      ]),
      el('span', { class: 'when', text: memory.date }),
    ]),
  ])

  return {
    node: el('div', { class: 'page', id: 'memories-screen' }, [
      el('div', { class: 'page-head' }, [
        roundButton('back', () => go('home'), { id: 'memories-home', label: 'go home' }),
        el('h1', { text: 'Memories' }),
      ]),
      memories.length
        ? el('div', { class: 'memory-list' }, memories.map(entry))
        : el('div', { class: 'empty' }, [
            el('h2', { text: 'No memories yet' }),
            text('Play together, and go and meet somebody at the park.'),
          ]),
    ]),
    scene: 'room',
  }
}
