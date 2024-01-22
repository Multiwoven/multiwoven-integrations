---
name: Pull Request Template
about: Template for creating a new pull request for a Multiwoven integrations gem
title: "[TYPE]: Brief Description" # e.g. Enhance Salesforce Connector Performance
labels: ''
assignees: ''

---

## Description
<!-- A brief description of what this pull request does. Include the purpose of the change and any relevant context. e.g
 This PR enhances the performance of the Salesforce connector by implementing batch data processing. -->

## Related Issue
<!-- Link to any related issues or indicate 'None' if applicable e.g
 Relates to issue #123 - 'Improve Salesforce Connector Efficiency'. If none, state 'None'. -->

## Type of Change
- [ ] New Connector (Destination or Source Connector)
- [ ] Bug fix (non-breaking change which fixes an issue)
- [ ] New feature (non-breaking change which adds functionality)
- [ ] Breaking change (fix or feature that would impact existing functionality)
- [ ] Documentation update

## How Has This Been Tested?
<!-- Describe the tests that you ran to verify your changes. Provide instructions so we can reproduce. Please also list any relevant details for your test configuration. e.g
Tested with a batch of 10,000 records to ensure data integrity and monitor performance improvements. -->

## Checklist:
- [ ] My code follows Ruby style guidelines
- [ ] I have performed a self-review of my own code
- [ ] I have commented my code, particularly in hard-to-understand areas
- [ ] I have made corresponding changes to the documentation
- [ ] My changes generate no new warnings
- [ ] I have added tests that prove my fix is effective or that my feature works
- [ ] New and existing unit tests pass locally with my changes
- [ ] Added the new connector in rollout.rb

## Screenshots (if appropriate):

## Additional Notes
<!-- Any additional information that you think is important. e.g
The batch processing implementation may require further optimization based on data size. -->

## Gem Specific Questions
- [ ] Have you updated the version number of the gem?
- [ ] Have you updated the gemspec file with any new dependencies or updates?
- [ ] Have you run all test suites and ensured they pass?

## Documentation
- [ ] Have you ensured that your changes for new connector are documented in the [docs repo](https://github.com/Multiwoven/docs) or relevant documentation files?
- [ ] If your changes affect public API, have you updated the documentation?

## Merging and Release Plan
<!-- Outline your plan for merging and releasing the changes. This could include steps for manual testing, release scheduling, or coordinating with other team members. e.g
Plan to merge after one additional team member reviews for accuracy and relevance. -->
