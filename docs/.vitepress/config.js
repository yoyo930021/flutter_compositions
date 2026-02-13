import { defineConfig } from 'vitepress'

export default defineConfig({
  base: '/flutter_compositions/',
  title: 'Flutter Compositions',
  description: 'A Vue-like Composition API for Flutter.',

  themeConfig: {
    socialLinks: [
      { icon: 'github', link: 'https://github.com/yoyo930021/flutter_compositions' }
    ],

    nav: [
      { text: 'Guide', link: '/guide/introduction' },
      { text: 'Internals', link: '/internals/architecture' },
      { text: 'Testing', link: '/testing/testing-guide' },
      { text: 'Lints', link: '/lints/' },
      {
        text: 'API Reference',
        link: 'https://pub.dev/documentation/flutter_compositions/latest/'
      },
      {
        text: 'GitHub',
        link: 'https://github.com/yoyo930021/flutter_compositions'
      }
    ],

    sidebar: {
      '/guide/': [
        {
          text: 'Getting Started',
          items: [
            { text: 'Introduction', link: '/guide/introduction' },
            { text: 'Quick Start', link: '/guide/getting-started' },
            { text: 'The Composition Widget', link: '/guide/composition-widget' },
          ]
        },
        {
          text: 'Core Concepts',
          items: [
            { text: 'Reactivity Fundamentals', link: '/guide/reactivity-fundamentals' },
            { text: 'Watchers & Effects', link: '/guide/watchers-and-effects' },
            { text: 'Lifecycle Hooks', link: '/guide/lifecycle-hooks' },
            { text: 'Reactive Props', link: '/guide/reactive-props' },
            { text: 'Dependency Injection', link: '/guide/dependency-injection' },
          ]
        },
        {
          text: 'Working with Composables',
          items: [
            { text: 'Built-in Composables', link: '/guide/built-in-composables' },
            { text: 'Async Operations', link: '/guide/async-operations' },
            { text: 'Animations', link: '/guide/animations' },
            { text: 'Forms', link: '/guide/forms' },
            { text: 'State Management', link: '/guide/state-management' },
            { text: 'Creating Your Own', link: '/guide/creating-composables' },
          ]
        },
        {
          text: 'Going Further',
          items: [
            { text: 'Migrating from StatefulWidget', link: '/guide/from-stateful-widget' },
            { text: 'Best Practices & Pitfalls', link: '/guide/best-practices' },
          ]
        }
      ],
      '/internals/': [
        {
          text: 'Internals',
          items: [
            { text: 'Architecture Overview', link: '/internals/architecture' },
            { text: 'Reactivity System', link: '/internals/reactivity-system' },
            { text: 'Performance', link: '/internals/performance' },
            { text: 'Design Trade-offs', link: '/internals/design-trade-offs' },
          ]
        }
      ],
      '/testing/': [
        {
          text: 'Testing',
          items: [
            { text: 'Testing Guide', link: '/testing/testing-guide' },
          ]
        }
      ],
      '/lints/': [
        {
          text: 'Lints',
          items: [
            { text: 'Getting Started', link: '/lints/index' },
            { text: 'Rule Catalogue', link: '/lints/rules' },
          ]
        }
      ]
    },

    footer: {
      message: 'Released under the MIT License.',
      copyright: 'Copyright © 2024-present yoyo930021'
    },

    docFooter: {
      prev: 'Previous page',
      next: 'Next page'
    }
  }
})
