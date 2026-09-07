// The inbox: thank-you notes, badge receipts and gifts.
import { el, row, card, button, text, pill, icon } from '../ui.js'

export function MailScreen({ game }) {
  if (game.unreadMail() > 0) game.readAllMail()
  const letters = game.mail()

  const letterCard = (letter) => {
    const node = card([
      row([
        icon('mail'),
        el('div', { class: 'grow' }, [
          el('h3', { text: letter.title }),
          text(letter.body),
          el('span', { class: 'muted', text: new Date(letter.at * 1000).toISOString().slice(0, 10) }),
        ]),
        ...Object.entries(letter.reward ?? {})
          .filter(([, n]) => n > 0)
          .map(([kind, n]) => pill(`+${n} ${kind}`)),
        !letter.claimed && button('Collect', () => game.claimMail(letter.id), 'primary', {}),
      ]),
    ])
    if (!letter.claimed) node.style.background = '#fdf1d4'
    return node
  }

  return {
    node: el('div', { class: 'screen page', id: 'mail-screen' }, [
      row([icon('mail'), el('h1', { text: 'Inbox' }), el('div', { class: 'grow' }),
        game.claimableMail() > 0 && pill(`${game.claimableMail()} gift to collect`, 'red')], 'head'),
      el('div', { class: 'scroll' }, [
        letters.length
          ? el('div', { class: 'col' }, letters.map(letterCard))
          : card([el('h2', { text: 'Nothing yet' }),
            text('Letters arrive when you earn a badge, finish a chapter, or find an animal its forever home.')]),
      ]),
    ]),
    scene: 'home',
  }
}
