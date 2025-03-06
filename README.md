# RPSLS
## RPSLS (Rock-Paper-Scissors-Lizard-Spock) Smart Contract
Rock-Paper-Scissors-Lizard-Spock (RPSLS) ที่เขียนด้วยภาษา Solidity โดยเป็นเกมที่ให้ผู้เล่นสองคนเข้าร่วมเกม, ชำระค่าธรรมเนียมการเข้าเกม 1 ether, เลือกตัวเลือกในเกม (Rock, Paper, Scissors, Lizard, Spock), และตัดสินผู้ชนะตามกฎของเกม Rock-Paper-Scissors-Lizard-Spock

เกมนี้มีการใช้กลไก commit-reveal เพื่อซ่อนตัวเลือกของผู้เล่นและหลีกเลี่ยงปัญหาการถูกทำ front-running (การได้ประโยชน์จากการรู้ล่วงหน้าว่าผู้เล่นคนอื่นเลือกอะไร) นอกจากนี้ยังมีการจัดการกับกรณีที่เกมไม่สามารถเริ่มได้ หรือหากผู้เล่นไม่สามารถเข้าร่วมได้ตามเวลาที่กำหนดได้อีกด้วย

## การทำงานของเกม
1. การเข้าร่วมเกม: ผู้เล่นจะต้องชำระค่าธรรมเนียม 1 ether เพื่อเข้าร่วมเกม
2. การเลือก: หลังจากที่มีผู้เล่นครบสองคน, ผู้เล่นทั้งสองจะต้องเลือกตัวเลือก (Rock, Paper, Scissors, Lizard, Spock) และทำการ commit ตัวเลือกในรูปแบบของ hash
3. การเปิดเผยตัวเลือก: เมื่อผู้เล่นทั้งสองทำการ commit ตัวเลือกแล้ว, พวกเขาจะต้องทำการ reveal ตัวเลือกที่แท้จริงของตน
4. การตัดสินผู้ชนะ: หลังจากทั้งสองฝ่ายทำการเปิดเผยตัวเลือกแล้ว, ระบบจะทำการตัดสินผู้ชนะตามกฎของเกม RPSLS
5. การจัดการความล่าช้า: หากมีผู้เล่นที่ไม่เข้าร่วมภายในเวลาที่กำหนด (timeout), ผู้เล่นที่เข้าร่วมแล้วสามารถรับรางวัลทั้งหมดได้

### การป้องกันการล็อกเงิน
ในฟังก์ชัน `addPlayer()` ผู้เล่นจะต้องชำระค่าธรรมเนียมการเข้าร่วมเกมที่เป็น 1 ether ก่อนถึงจะสามารถเข้าร่วมเกมได้ หากผู้เล่นไม่ได้ส่งเงิน 1 ether หรือเงินไม่ครบ, ฟังก์ชันจะยกเลิก (revert) การทำธุรกรรมโดยไม่ทำการล็อกเงินไว้ในสัญญา
```
require(msg.value == 1 ether, "Entry fee is 1 ether.");
```
- ฟังก์ชัน `addPlayer()` ตรวจสอบว่าเงินที่ส่งมาพร้อมกับการเข้าร่วมเกมเป็น 1 ether ถ้าไม่ครบจะมีการยกเลิกธุรกรรม (revert)

### กลไก Commit-Reveal
เพื่อป้องกัน front-running หรือการรู้ล่วงหน้าของตัวเลือกจากผู้เล่นคนอื่น, ใช้กลไก commit-reveal ดังนี้:
1. ผู้เล่นทำการ commit ตัวเลือกของตนโดยการส่ง hash ของตัวเลือกและข้อความลับ (secret)
2. ผู้เล่นทำการ reveal ตัวเลือกจริง ๆ ในภายหลังเพื่อให้ตรงกับ hash ที่ได้ commit ไว้ก่อนหน้านี้
```
function commit(bytes32 dataHash) public {
    require(commits[msg.sender].block == 0, "Commit already made");
    commits[msg.sender] = Commit({ commit: dataHash, block: uint64(block.number), revealed: false });
    emit CommitHash(msg.sender, dataHash, uint64(block.number));
}

function reveal(uint choice, string memory secret) public {
    require(commits[msg.sender].revealed == false, "Already revealed");
    require(commits[msg.sender].block != 0, "No commit found");
    bytes32 computedHash = getHash(choice, secret);
    require(computedHash == commits[msg.sender].commit, "Reveal does not match commit");
    commits[msg.sender].revealed = true;
    emit RevealHash(msg.sender, choice);
}
```
- ผู้เล่นต้อง commit ก่อน แล้วถึงจะสามารถ reveal ตัวเลือกได้ในภายหลัง

### การจัดการกับความล่าช้า
ฟังก์ชัน `claimWinDueToTimeout()` จะใช้ในกรณีที่มีผู้เล่นไม่เข้าร่วมเกมหรือไม่ทำการเลือกภายในเวลาที่กำหนด (เช่น ผู้เล่นไม่ทำการเล่นภายในเวลา 5 นาที) ผู้เล่นที่ทำการเล่นจะได้รับรางวัล
```
function claimWinDueToTimeout() public {
    require(numPlayer == 2, "Game not started.");
    require(timeUnit.hasTimedOut(timeoutMinutes), "Not timed out yet.");
    if (player_not_played[players[0]]) {
        address payable winner = payable(players[1]);
        winner.transfer(reward);
    } else if (player_not_played[players[1]]) {
        address payable winner = payable(players[0]);
        winner.transfer(reward);
    }
    _resetGame();
}
```
- หากผู้เล่นไม่ทำการเลือกภายในเวลาที่กำหนด (5 นาที), ผู้เล่นที่ทำการเลือกแล้วจะได้รับรางวัลทั้งหมด

### การเปิดเผยและตัดสินผู้ชนะ
เมื่อทั้งสองผู้เล่นทำการเปิดเผยตัวเลือกแล้ว, ระบบจะตัดสินผู้ชนะตามกฎ RPSLS 
```
function _isWinner(uint choiceA, uint choiceB) private pure returns (bool) {
        return (
            (choiceA == 0 && (choiceB == 1 || choiceB == 3)) || // Rock crushes Scissors & Lizard
            (choiceA == 1 && (choiceB == 2 || choiceB == 3)) || // Scissors cuts Paper & decapitates Lizard
            (choiceA == 2 && (choiceB == 0 || choiceB == 4)) || // Paper covers Rock & disproves Spock
            (choiceA == 3 && (choiceB == 2 || choiceB == 4)) || // Lizard eats Paper & poisons Spock
            (choiceA == 4 && (choiceB == 0 || choiceB == 1))    // Spock vaporizes Rock & smashes Scissors
        );
    }
```
และทำการโอนรางวัลให้ผู้ชนะ
```
function _checkWinnerAndPay() private {
    uint p0Choice = player_choice[players[0]];
    uint p1Choice = player_choice[players[1]];
    address payable account0 = payable(players[0]);
    address payable account1 = payable(players[1]);

    if (_isWinner(p0Choice, p1Choice)) {
        account0.transfer(reward);
    } else if (_isWinner(p1Choice, p0Choice)) {
        account1.transfer(reward);
    } else {
        account0.transfer(reward / 2);
        account1.transfer(reward / 2);
    }
    _resetGame();
}
```
- ฟังก์ชันนี้จะทำการตรวจสอบผู้ชนะจากตัวเลือกที่ผู้เล่นเลือก และทำการโอนเงินรางวัลตามที่กำหนด





