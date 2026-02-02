// login.js: reusable login function for Selenium tests
const fs = require('fs');
const path = require('path');
const { By } = require('selenium-webdriver');
module.exports = async function loginWithAdminCredentials(driver) {
   const tmpDir = process.env.TEMP || process.env.TMP || 'C:\\tmp';
   const credsPath = path.join(tmpDir, 'multiflexi_admin_credentials.json');
   const creds = JSON.parse(fs.readFileSync(credsPath, 'utf8'));
   await driver.findElement(By.name("login")).click();
   await driver.findElement(By.name("login")).sendKeys(creds.username);
   await driver.findElement(By.name("password")).sendKeys(creds.password);
   await driver.findElement(By.id("signinbuttonmenu")).click();
};