# commitlint.config.js
# 
# Configuration for commitlint
# Install: npm install -g @commitlint/cli @commitlint/config-conventional
# Setup: cp commitlint.config.js ./ && npx husky add .git/hooks/commit-msg 'npx commitlint --edit $1'

module.exports = {
  extends: ['@commitlint/config-conventional'],
  rules: {
    // Type enum - all allowed commit types
    'type-enum': [
      2,
      'always',
      [
        'feat',      // New feature
        'fix',       // Bug fix
        'docs',      // Documentation only
        'style',     // Code style changes (formatting, etc.)
        'refactor',  // Code refactoring
        'perf',      // Performance improvements
        'test',      // Adding/updating tests
        'build',     // Build system changes
        'ci',        // CI configuration changes
        'chore',     // Other changes (no src/test changes)
        'revert',    // Revert previous commit
        'security',  // Security fixes/improvements
        'deps',      // Dependency updates
        'i18n',      // Internationalization
        'a11y',      // Accessibility
        'analytics', // Analytics/tracking
        'config',    // Configuration changes
        'hotfix',    // Critical production fix
        'release',   // Release commit
      ],
    ],
    // Subject must not be empty
    'subject-empty': [2, 'never'],
    // Subject must be between 10 and 72 characters
    'subject-min-length': [2, 'always', 10],
    'subject-max-length': [2, 'always', 72],
    // Subject must start with lowercase
    'subject-case': [2, 'always', 'lower-case'],
    // Subject must not end with period
    'subject-full-stop': [2, 'never', '.'],
    // Type must be lowercase
    'type-case': [2, 'always', 'lower-case'],
    // Type must not be empty
    'type-empty': [2, 'never'],
    // Scope must be lowercase
    'scope-case': [2, 'always', 'lower-case'],
    // Scope max length
    'scope-max-length': [2, 'always', 20],
    // Scope min length (if provided)
    'scope-min-length': [1, 'always', 2],
    // Header (full first line) max length
    'header-max-length': [2, 'always', 100],
    // Body should have leading blank line
    'body-leading-blank': [2, 'always'],
    // Footer should have leading blank line
    'footer-leading-blank': [1, 'always'],
  },
  // Custom plugins for additional validation
  plugins: [
    {
      rules: {
        'no-prohibited-words': (parsed) => {
          const prohibited = ['WIP', 'wip', 'TODO', 'FIXME', 'HACK', 'XXX'];
          const message = parsed.raw.toLowerCase();
          const found = prohibited.filter(word => 
            message.includes(word.toLowerCase())
          );
          
          if (found.length > 0) {
            return [
              false,
              `Prohibited word(s) found: ${found.join(', ')}. Remove them from commit message.`,
            ];
          }
          return [true];
        },
      },
    },
  ],
  // Enable custom rules
  extends: ['@commitlint/config-conventional'],
  rules: {
    ...module.exports?.rules,
    'no-prohibited-words': [2, 'always'],
  },
};
