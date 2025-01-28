import recurring from './recurring.json'
import edu from './edu.json'

interface LinkRecord {
  url: string
  label: string
  hidden?: boolean
}

interface LinkRecordList {
  id: string
  _: LinkRecord[]
}

const _: LinkRecordList[] = [
  {
    id: 'Recurring',
    _: recurring,
  },
  {
    id: 'Edu',
    _: edu,
  },
]

const SEARCH_CACHE = new Map()
const BUILD_CACHE = new Map()

const $ = function $(selector: string, context = document) {
  const elements: HTMLElement[] = Array.from(context.querySelectorAll(selector))

  return {
    elements,

    clear() {
      this.elements.forEach(element => {
        element.innerHTML = ''
      })

      return this
    },

    html(newHtml: string) {
      this.elements.forEach(element => {
        element.innerHTML += newHtml
      })

      return this
    },

    css(newCss: string) {
      this.elements.forEach(element => {
        Object.assign(element.style, newCss)
      })

      return this
    },

    focus() {
      ;(context.querySelector(selector) as HTMLElement)?.focus()

      return this
    },

    val() {
      return context.querySelector(selector)?.value
    },

    on<K extends keyof HTMLElementEventMap>(
      event: K,
      handler: EventListenerOrEventListenerObject,
      options?: AddEventListenerOptions,
    ) {
      this.elements.forEach(element => {
        element.addEventListener(event, handler, options)
      })

      return this
    },
  }
}

function caseInsensitiveCmp(str: string, query: string) {
  return str.toLowerCase().indexOf(query) !== -1
}

function search() {
  const query = $('#find').val()
  const results: LinkRecordList[] = [
    {
      id: 'Filtered',
      _: [],
    },
  ]

  let found = false

  if (query.length === 0 || query.trim().length === 0) {
    $('#main').clear()
    build(_)

    return
  }

  const normalizedQuery = query.toLowerCase()

  if (SEARCH_CACHE.has(normalizedQuery)) {
    $('#main').clear()
    build(SEARCH_CACHE.get(normalizedQuery))

    return
  }

  _.forEach(recordSet => {
    recordSet._.forEach(record => {
      if (
        caseInsensitiveCmp(record.label, normalizedQuery) ||
        caseInsensitiveCmp(record.url, normalizedQuery)
      ) {
        results[0]._.push(record)
        found = true
      }
    })
  })

  if (found) {
    SEARCH_CACHE.set(normalizedQuery, results)
  }

  $('#main').clear()
  build(found ? results : _)
}

function build(records: LinkRecordList[]) {
  for (const { id, _ } of records) {
    let node = `<section><h1>${id}</h1><ul>`

    for (const { url, label, hidden } of _) {
      if (!hidden) {
        if (BUILD_CACHE.has(url)) {
          node += BUILD_CACHE.get(url)
        } else {
          const li = `<li><a href="${url}">${label}</a></li>`
          node += li

          BUILD_CACHE.set(url, li)
        }
      }
    }

    node += '</ul></section>'
    $('#main').html(node)
  }
}

;(() => {
  build(_)
  $('#find').on('keyup', search).on('change', search).focus()
})()
