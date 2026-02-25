// driver.js: shared WebDriver factory for Selenium tests
const { Builder } = require('selenium-webdriver');
const chrome = require('selenium-webdriver/chrome');

async function createDriver() {
    const options = new chrome.Options();
    options.addArguments('--no-sandbox');
    options.addArguments('--disable-dev-shm-usage');

    if (process.env.HEADLESS === '1' || process.env.CI) {
        options.addArguments('--headless');
    }

    const driver = await new Builder()
        .forBrowser('chrome')
        .setChromeOptions(options)
        .build();

    return driver;
}

module.exports = { createDriver };
