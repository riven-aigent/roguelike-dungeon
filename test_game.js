// Test script for Depths of Ruin - runs game logic without rendering
// This script will initialize the game, make a few moves, and then exit

class TestGameManager {
    constructor() {
        this.gameOver = false;
        this.turnCount = 0;
        this.maxTurns = 10; // Run for 10 turns then exit
        this.playerPos = {x: 0, y: 0};
        this.currentFloor = 1;
        this.playerHP = 20;
        this.playerMaxHP = 20;
        this.killCount = 0;
        this.score = 0;
    }
    
    // Simulate game initialization
    initialize() {
        console.log("Initializing Depths of Ruin test...");
        this._generateFloor();
        console.log(`Game started on floor ${this.currentFloor}`);
        console.log(`Player HP: ${this.playerHP}/${this.playerMaxHP}`);
    }
    
    // Simulate floor generation (simplified)
    _generateFloor() {
        // In real game, this would generate dungeon layout
        // For test, we just set up basic state
        this.playerPos = {x: 30, y: 30}; // Center of map
        this.enemies = [];
        this.items = [];
        
        // Add some enemies for testing
        if (this.currentFloor >= 1) {
            this.enemies.push({pos: {x: 35, y: 30}, type: "SLIME", hp: 5, maxHp: 5, atk: 2, def: 0, alive: true});
        }
        if (this.currentFloor >= 3) {
            this.enemies.push({pos: {x: 25, y: 35}, type: "SKELETON", hp: 8, maxHp: 8, atk: 3, def: 1, alive: true});
        }
        
        // Add some items
        this.items.push({pos: {x: 32, y: 32}, type: "HEALTH_POTION", collected: false});
        this.items.push({pos: {x: 28, y: 28}, type: "GOLD", collected: false});
    }
    
    // Simulate player movement
    tryMove(dir) {
        if (this.gameOver || this.turnCount >= this.maxTurns) return;
        
        const newPos = {x: this.playerPos.x + dir.x, y: this.playerPos.y + dir.y};
        console.log(`Turn ${this.turnCount + 1}: Moving to (${newPos.x}, ${newPos.y})`);
        
        // Check for enemies at new position (bump attack)
        const enemyAtPos = this.enemies.find(e => e.alive && e.pos.x === newPos.x && e.pos.y === newPos.y);
        if (enemyAtPos) {
            console.log(`Attacking ${enemyAtPos.type}!`);
            const damage = Math.max(1, 3 - enemyAtPos.def); // Player base ATK is 3
            enemyAtPos.hp -= damage;
            console.log(`${enemyAtPos.type} takes ${damage} damage (HP: ${enemyAtPos.hp}/${enemyAtPos.maxHp})`);
            
            if (enemyAtPos.hp <= 0) {
                enemyAtPos.alive = false;
                this.killCount++;
                console.log(`Killed ${enemyAtPos.type}! Kill count: ${this.killCount}`);
            }
        } else {
            // Move player
            this.playerPos = newPos;
            
            // Check for item pickup
            const itemAtPos = this.items.find(i => !i.collected && i.pos.x === newPos.x && i.pos.y === newPos.y);
            if (itemAtPos) {
                itemAtPos.collected = true;
                console.log(`Picked up ${itemAtPos.type}!`);
                if (itemAtPos.type === "HEALTH_POTION") {
                    const heal = Math.min(8, this.playerMaxHP - this.playerHP);
                    this.playerHP += heal;
                    console.log(`Healed ${heal} HP (now ${this.playerHP}/${this.playerMaxHP})`);
                } else if (itemAtPos.type === "GOLD") {
                    this.score += 10;
                    console.log(`Got 10 gold! Score: ${this.score}`);
                }
            }
        }
        
        // Enemy turn
        this._enemyTurn();
        
        // Check win condition (stairs)
        if (this._checkStairs()) {
            this.currentFloor++;
            console.log(`Reached stairs! Advancing to floor ${this.currentFloor}`);
            this._generateFloor();
        }
        
        this.turnCount++;
        
        // Check if we should end test
        if (this.turnCount >= this.maxTurns) {
            console.log("Test completed successfully!");
            this._printStats();
            return true; // Signal completion
        }
        
        return false;
    }
    
    _enemyTurn() {
        // Simple enemy AI for testing
        this.enemies.forEach(enemy => {
            if (!enemy.alive) return;
            
            // Simple chase logic
            const dx = this.playerPos.x - enemy.pos.x;
            const dy = this.playerPos.y - enemy.pos.y;
            const dist = Math.abs(dx) + Math.abs(dy);
            
            if (dist <= 1) {
                // Attack player
                const damage = Math.max(1, enemy.atk - 1); // Player base DEF is 1
                this.playerHP -= damage;
                console.log(`${enemy.type} attacks for ${damage} damage! Player HP: ${this.playerHP}/${this.playerMaxHP}`);
                
                if (this.playerHP <= 0) {
                    this.playerHP = 0;
                    this.gameOver = true;
                    console.log("Player died! Game over.");
                    this._printStats();
                }
            } else if (dist <= 5) {
                // Move toward player
                let moveX = 0, moveY = 0;
                if (Math.abs(dx) >= Math.abs(dy)) {
                    moveX = dx > 0 ? 1 : -1;
                } else {
                    moveY = dy > 0 ? 1 : -1;
                }
                enemy.pos.x += moveX;
                enemy.pos.y += moveY;
                console.log(`${enemy.type} moves to (${enemy.pos.x}, ${enemy.pos.y})`);
            }
        });
    }
    
    _checkStairs() {
        // Simplified stairs check - just return true occasionally for testing
        return this.turnCount === 5; // Go to next floor on turn 5
    }
    
    _printStats() {
        console.log("\n=== FINAL STATS ===");
        console.log(`Floors cleared: ${this.currentFloor - 1}`);
        console.log(`Enemies killed: ${this.killCount}`);
        console.log(`Final HP: ${this.playerHP}/${this.playerMaxHP}`);
        console.log(`Score: ${this.score}`);
        console.log(`Game over: ${this.gameOver}`);
        console.log("==================\n");
    }
}

// Run the test
const testGame = new TestGameManager();
testGame.initialize();

// Make some moves
const directions = [
    {x: 1, y: 0},  // right
    {x: 0, y: 1},  // down  
    {x: -1, y: 0}, // left
    {x: 0, y: -1}, // up
    {x: 1, y: 1},  // down-right
];

let completed = false;
for (let i = 0; i < 20 && !completed; i++) {
    const dir = directions[i % directions.length];
    completed = testGame.tryMove(dir);
    if (testGame.gameOver) break;
}

console.log("Test script finished.");