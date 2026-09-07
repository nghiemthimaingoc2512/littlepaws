// The daily visit: streak, today's five small jobs, and their rewards.
import { el, row, card, button, text, pill, icon } from '../ui.js'
import { DAILY_TASKS, DAILY_CLEAR_HEARTS, DAILY_CLEAR_GEMS, AD_REWARD_COINS } from '../state.js'
import { showRewardedVideo } from '../main.js'

export function DailyScreen({ game }) {
  const taskRow = (task) => {
    const done = game.taskDone(task)
    const claimed = game.taskClaimed(task)
    return el('div', { class: 'card tight', style: { background: done ? '#eef6e6' : 'var(--cream)' } }, [
      row([
        icon(done ? 'check' : 'paw'),
        el('div', { class: 'grow' }, [
          el('h3', { text: task.label }),
          task.target > 1 && el('span', { class: 'muted', text: `${game.taskProgress(task)} / ${task.target}` }),
        ]),
        pill(`+${task.coins} coins`, 'gold'),
        claimed
          ? pill('collected', 'sage')
          : button(done ? 'Collect' : 'Not yet', () => game.claimTask(task.id),
            done ? 'primary' : 'soft', { disabled: !done }),
      ]),
    ])
  }

  const list = card([
    el('h2', { text: 'To Do Today' }),
    text('Five small things. None of them expire in a way that costs you anything — the list simply starts fresh tomorrow.'),
    ...DAILY_TASKS.map(taskRow),
    text(`${game.tasksDoneToday()} of ${DAILY_TASKS.length} done — finish them all for +${DAILY_CLEAR_HEARTS} heart and +${DAILY_CLEAR_GEMS} gems.`),
  ])

  const side = el('div', { class: 'col', style: { width: '340px', flex: 'none' } }, [
    card([
      el('h2', { text: 'Coming back' }),
      text('Visiting on consecutive days pays a little more each time, and every seventh day adds gems. Missing a day only resets the counter — nothing is taken away.'),
      pill(`Current streak: ${game.streak()} ${game.streak() === 1 ? 'day' : 'days'}`, 'pink'),
    ]),
    card([
      row([icon('heart'), el('h2', { text: 'Hearts' })]),
      text('Hearts come from finishing the day\'s list and from finding an animal its forever home. They buy keepsakes and never gate a chapter.'),
      pill(`You have ${game.hearts()}`, 'red'),
    ]),
    button(`Watch a short video  +${AD_REWARD_COINS} coins`, () => showRewardedVideo(() => game.grantAdReward()),
      'sage', { disabled: !game.adAvailable() }),
  ])

  return {
    node: el('div', { class: 'screen page', id: 'daily-screen' }, [
      row([icon('calendar'), el('h1', { text: 'Daily' }), el('div', { class: 'grow' }),
        pill(`Day ${game.streak()} in a row`, 'pink')], 'head'),
      el('div', { class: 'scroll' }, [row([list, side], 'grow')]),
    ]),
    scene: 'home',
  }
}
