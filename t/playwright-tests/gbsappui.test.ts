import { test, expect } from '@playwright/test';

//Testing full analysis process
test('Full analysis setup', async ({ page }) => {
    await page.goto('https://gbsappui.breedbase.org');

    //Select SGN
    await page.locator('#instance_dropdown').selectOption('https://solgenomics.net');
    await expect(page.getByRole('button', { name: 'Select' })).toBeVisible();
    await page.getByRole('button', { name: 'Select' }).click();

    //Login to SGN
    await page.getByPlaceholder('Username').click();
    await page.getByPlaceholder('Username').fill('janedoe');
    await page.getByPlaceholder('Password').click();
    await page.getByPlaceholder('Password').fill('secretpw');
    await page.getByLabel('Login').getByRole('button', { name: 'Login' }).click();

    //Authorize gbsappui access to breedbase
    await page.getByRole('button', { name: 'Authorize Access' }).click();

    //Choose reference genome
    await page.locator('[id="Sol\\ Genomics\\ Network"]').selectOption('slv4.fasta');
    await page.getByRole('button', { name: 'Select' }).click();
    await page.locator('#fastq').setInputFiles('/home/awl/breedbase_dockerfile/cxgn/gbsappui/t/playwright-tests/fixtures/test10.fastq.gz');
    await page.getByRole('button', { name: 'Upload' }).click();

    //Select imputation, input email, and submit analysis
    await page.getByLabel('Post-analysis imputation').check();
    await page.locator('#email_input').click();
    await page.locator('#email_input').fill('awl67@cornell.edu');
    await page.getByRole('button', { name: 'Submit Analysis' }).click();

    //Cancel analysis
    await page.on('dialog', dialog => dialog.accept());
    await page.locator('#cancel_button').click();

    //Check that "Analysis Canceled" page shows up
    await expect(page.locator('#Cancel')).toBeVisible();

    //Check that we returned to the main page
    await expect(page.locator('#instance_dropdown')).toBeVisible();
});

//Further testing on index page only
test('Index page, login, and logout', async ({ page }) => {
    await page.goto('https://gbsappui.breedbase.org');

    //Select SGN
    await page.locator('#instance_dropdown').selectOption('https://solgenomics.net');
    await page.getByRole('button', { name: 'Select' }).click();

    //Login to SGN
    await page.getByPlaceholder('Username').click();
    await page.getByPlaceholder('Username').fill('janedoe');
    await page.getByPlaceholder('Password').click();
    await page.getByPlaceholder('Password').fill('secretpw');
    await page.getByLabel('Login').getByRole('button', { name: 'Login' }).click();
    await page.getByRole('button', { name: 'Authorize Access' }).click();

    //Check that we're on the next page
    await expect(page.getByText('Choose a reference genome:')).toBeVisible();

    //Check that we're logged in as jane doe
    await expect(page.getByText('janedoe')).toBeVisible();

    //Logout
    await page.on('dialog', dialog => dialog.accept());
    await page.locator('#logout_button').click();

    //Check that logout worked
    await expect(page.locator('#please_login')).toBeVisible();
});
