-----------------------------------------------------------------------------
# Gbsappui Test Suite
-----------------------------------------------------------------------------

This is the GBSAPPUI test suite, which helps us verify that code is working as it should.

Active Testing:

Browser tests depend on Playwright (playwright.dev). To run all tests, run the following command from the `gbsappui/t` folder:

```$xslt
npx playwright test
```

To run a single files test, run this command, changing the file path to the file you want:

```$xslt
npx playwright test playwright-tests/gbsappui.test.ts
```


-----------------------------------------------------------------------------
#Testing Configuration
-----------------------------------------------------------------------------

-----------------------------------------------------------------------------
#Active Tests
-----------------------------------------------------------------------------

## t/playwright-tests/

Browser tests using the playwright software

-----------------------------------------------------------------------------
#Test Environment
-----------------------------------------------------------------------------

## t/playwright-tests/fixture/

Contains test data, such as fastq files for a test analysis.
