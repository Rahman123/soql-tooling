import { completionsFor } from './completion';

describe('Code Completion', () => {
  it.only('xxxx', () => {
    // const completions = completionsFor('SELECT id FROM Account', 0, 0);
    const completions = completionsFor('SELECT id ', 1, 10);
    expect(completions).toBeGreaterThan(0);
  });
});
