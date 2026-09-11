// Everything Sprint 1 knows about. Five pets: yours, and four to meet.
export const MY_PET = 'calico'

export const PETS = [
  {
    id: 'calico', name: 'Mochi', kind: 'Calico Cat',
    line: 'Your cat. Sits against your side and purrs loud enough to feel.',
  },
  {
    id: 'kitten_grey', name: 'Pebble', kind: 'Silver Kitten',
    line: 'Asleep in a flower planter with both paws tucked under.',
    greeting: 'A small grey kitten blinks up at you from the flowerbed.',
  },
  {
    id: 'cat_ginger', name: 'Biscuit', kind: 'Ginger Cat',
    line: 'Folds into a perfect loaf on the warmest tile in the park.',
    greeting: 'A ginger cat is sunbathing on the path, entirely unbothered.',
  },
  {
    id: 'dog_shiba', name: 'Sesame', kind: 'Shiba',
    line: 'Ran three laps of the park before stopping to say hello.',
    greeting: 'A shiba skids to a halt in front of you, grinning.',
  },
  {
    id: 'dog_poodle', name: 'Honey', kind: 'Poodle',
    line: 'Greets everyone on the path, then checks nobody was left out.',
    greeting: 'A curly poodle trots over, tail going like a metronome.',
  },
]

export const pet = (id) => PETS.find((p) => p.id === id) ?? PETS[0]
export const otherPets = () => PETS.filter((p) => p.id !== MY_PET)
