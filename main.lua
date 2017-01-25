local composer = require ("composer")
 composer.setVariable("setFuelUpgrade", 0)           -- goes up by 1. Max = 5
 composer.setVariable("setDefenseUpgrade", 0)        -- goes up by 0.14. Max = 0.7
 composer.setVariable("setAccelerationUpgrade", 0)   -- goes up by 1. Max = 5
 composer.setVariable("setHandlingUpgrade", 0)       -- goes up by 0.6. Max = 3
 composer.setVariable("globalMoney", 0)
 composer.gotoScene("title")