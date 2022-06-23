const { expect } = require("chai")
const { ethers } = require("hardhat")
const {	latest,	increaseTo, duration } = require('./time');

const FORTNIGHTS = 26
const DEPOSIT = 500
const TIME_TO_WAIT = 60 * 60 * 60 * 24 * 7 * 20 // 20 Weeks

describe("TimeLock", function () {

  it("Should allow deposits and withdraws", async function () {
    const accounts = await ethers.getSigners()
    const TimeLock = await ethers.getContractFactory("TimeLock")
    const timelock = await TimeLock.deploy()
    await timelock.deployed()

    // Deposit
    await timelock.deposit(FORTNIGHTS, accounts[1].address, {value: DEPOSIT})

    // Getters
    const lockedAmount = await timelock.getLockedAmount(accounts[1].address)
    expect(lockedAmount).to.equal(DEPOSIT)

    const cliffAmount =  Number(await timelock.getCliffAmount(accounts[1].address))
    // expect(cliffAmount).to.equal(500/26*26)

    // Increase Time
    let start = await latest()
    let end = start.add(duration.weeks(19))
    await increaseTo(end)

    // Withdraw

    const nextPay = await timelock.getNextPayDay(accounts[1].address)
    console.log(nextPay)
  })

})
