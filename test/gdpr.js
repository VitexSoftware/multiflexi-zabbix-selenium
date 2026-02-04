// gdpr.js: reusable function to handle GDPR consent banner in Selenium tests
module.exports = async function handleGdprConsent(driver) {
    try {
        const gdprAcceptButton = await driver.wait(
            require('selenium-webdriver').until.elementLocated(
                require('selenium-webdriver').By.id("consent-accept-all")
            ),
            3000
        );
        await gdprAcceptButton.click();
        await driver.sleep(500);
    } catch (e) {
        // GDPR banner might not be present
    }
};
