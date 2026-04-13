---
name: refine-plan
description: Evaluate and refine a plan before implementation begins. Use once you think you are ready to present a plan or design to the user.
---

# Confidence

Based on the following rules, how confident are you about your approach? Be brutally honest and do not sugarcoat your opinion.

Split the problem into its component parts. Assign each part an integer score from _1 to 10_ for the following categories:

Quality categories:

- Elegance. Does the solution feel right? 10 is most elegant.
- Simplicity. Can this be done with less? 10 is simplest.
- Readability. Can someone understand it in 30 seconds? 10 is most readable.
- Testability. Can simple unit tests be written for it? 10 is most testable. This category can be ignored if there are no existing tests in the workspace.
- Decoupling. Can pieces be changed independently? 10 is least coupled (most decoupled).
- Reusability. Does the solution reduce repetition? 10 is most reusable.
- Focus. Does each piece do exactly one thing? 10 is most focused.

Confidence categories:

- Feasibility. Do you know how to build it? Are there existing established patterns available? 10 is most feasible.
- Scope clarity. Are requirements well-defined? 10 is exact scope defined.

If the score is less than 10 for any subcategory, note how the score could be improved.

**Calculate the scores objectively and with care**.

After you have calculated the score for each subcategory, calculate the category scores by averaging the subcategory scores.

Only state the overall score at the end of your response, after your calculations.

If the score for any category is less than 10, state how it can be improved using the notes you stated for each subcategory, then take steps to improve the score to a 10. Don't ask the user before doing this.

If, after deep investigation, you are unable to find a high-scoring solution or answer, explain the problem to the user and ask for clarification. However, this should be avoided if possible.

Once you have calculated the scores and ways to improve, present the scores and improvements to the user.

If you make any adjustments to your approach, recalculate the score using the above method, in the same level of detail.

**Do not start implementation until both the quality and the confidence are at least a 9.**

## Plan Completeness Check

Before presenting the plan, verify:

- **Does the plan end with a commit step?** Every plan must include committing as its final task (per `git-usage`).
- **Does the plan handle edge cases?** Consider: What happens on failure? What about empty/null inputs? Concurrent operations? Large datasets? Don't just plan the happy path.
- **Are there assumptions that should be validated?** If the plan depends on specific conditions (e.g., a file existing, a service running, a specific data shape), note them explicitly.

Once ready to begin implementation, persist any learnings (e.g. update memory or session state).

> NOTE: If any of the rules contradict any existing coding styles, best practices, or suggestions within the current project then the rules can be overridden. However, if the rules _are_ overridden, this _must_ be **explicitly** mentioned to the user.
