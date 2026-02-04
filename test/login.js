// Updated login.js to match the structure of login2.spec.js
const { By, until } = require('selenium-webdriver');
const fs = require('fs');
const path = '/tmp/multiflexi_admin_credentials.json';
const handleGdprConsent = require('./gdpr');

module.exports = async function loginWithAdminCredentials(driver) {
  await driver.get("https://vyvojar.spoje.net/multiflexi/login.php");

  // Handle GDPR consent banner
  await handleGdprConsent(driver);

  // Ensure credentials file exists
  if (!fs.existsSync(path)) {
    throw new Error(`Credentials file not found: ${path}`);
  }

  const creds = JSON.parse(fs.readFileSync(path, 'utf8'));
  console.log(`Using credentials: Username=${creds.username}, Password=${creds.password}`);

  // Use the exact username and password from the credentials file
  await driver.findElement(By.name("login")).click();
  await driver.findElement(By.name("login")).sendKeys(creds.username);
  await driver.findElement(By.name("password")).click();
  await driver.findElement(By.name("password")).sendKeys(creds.password);
  await driver.findElement(By.id("signinbuttonmenu")).click();

  // Optionally, check for successful login
};