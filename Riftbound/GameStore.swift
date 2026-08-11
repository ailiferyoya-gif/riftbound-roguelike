import Foundation
import Combine

@MainActor
final class GameStore: ObservableObject {
    @Published private(set) var phase: GamePhase = .title
    @Published var homeTab: HomeTab = .heroes
    @Published private(set) var profile: ProfileState
    @Published private(set) var runMode: RunMode = .standard
    @Published private(set) var route = RouteCatalog.standard
    @Published private(set) var depth = 0
    @Published private(set) var roomNumber = 1
    @Published private(set) var currentRoom: RoomKind = .battle
    @Published private(set) var currentEnemy: Enemy?
    @Published private(set) var eventText = ""
    @Published private(set) var eventChoices: [EventChoice] = []
    @Published private(set) var rewardChoices: [Relic] = []
    @Published private(set) var relics: [Relic] = []
    @Published private(set) var showNextButton = false
    @Published private(set) var rewardChosen = false
    @Published private(set) var rewardText = ""
    @Published private(set) var hp = 100
    @Published private(set) var maxHP = 100
    @Published private(set) var mp = 24
    @Published private(set) var maxMP = 24
    @Published private(set) var attack = 14
    @Published private(set) var guardValue = 0
    @Published private(set) var potions = 2
    @Published private(set) var cycleGold = 0
    @Published private(set) var goldMultiplier = 1.0
    @Published private(set) var log: [CombatLogEntry] = []
    @Published private(set) var hasResume = false
    @Published private(set) var combatAnimation: CombatAnimation = .idle
    @Published private(set) var isAnimating = false
    @Published var toast: String?

    private let profileKey = "riftbound-ios-profile-v5"
    private let cycleKey = "riftbound-ios-cycle-v5"
    private var nextAttackBonus = 0
    private var discoveryBonus = 0
    private var animationToken = 0

    let areaNames = ["ヴェイル遺跡", "灯火の沼", "硝子城塞", "冠の虚空"]

    init() {
        profile = Self.loadProfile(key: "riftbound-ios-profile-v5")
        normalizeProfile()
        hasResume = UserDefaults.standard.data(forKey: cycleKey) != nil
    }

    var selectedHero: Hero {
        Hero.catalog.first(where: { $0.id == profile.selectedHero }) ?? Hero.catalog[0]
    }

    var selectedBuild: BuildType {
        BuildType(rawValue: profile.buildByHero[selectedHero.id] ?? "") ?? .balanced
    }

    var roomProgress: Double {
        guard route.count > 1 else { return 0 }
        return Double(max(0, roomNumber - 1)) / Double(route.count - 1)
    }

    var modeTitle: String { runMode.title }

    var currentAreaIndex: Int {
        if currentRoom == .boss { return 3 }
        if runMode == .deep { return min(2, max(0, (roomNumber - 1) / 6)) }
        return min(2, max(0, (roomNumber - 1) / 3))
    }

    var currentAreaName: String { areaNames[currentAreaIndex] }

    var currentSkills: [HeroSkill] { selectedHero.allSkills }

    func enterHome() {
        phase = .home
        homeTab = .heroes
    }

    func startNewRun(_ mode: RunMode = .standard) {
        runMode = mode
        depth = profile.depth
        route = routeFor(mode)
        roomNumber = 1
        currentRoom = .battle
        let hero = selectedHero
        let build = selectedBuild
        maxHP = hero.maxHP + upgrade("vitality") * 10 + build.hp
        maxMP = max(4, hero.maxMP + upgrade("arcana") * 4 + build.mp)
        attack = max(1, hero.attack + upgrade("might") * 3 + build.attack)
        hp = maxHP
        mp = maxMP
        guardValue = build.startingGuard + profile.shopGuard
        if mode == .weekly && weeklyRule.contains("守り") { guardValue += 30 }
        potions = mode == .weekly && weeklyRule.contains("ポーションなし") ? 0 : 2 + upgrade("alchemy") + profile.shopPotions
        cycleGold = 0
        goldMultiplier = 1 + Double(upgrade("fortune")) * 0.08 + profile.shopGoldBonus + (build == .arcane ? 0.05 : 0) + (mode == .weekly && weeklyRule.contains("ゴールド+40%") ? 0.4 : 0)
        relics = []
        rewardChoices = []
        rewardChosen = false
        showNextButton = false
        combatAnimation = .idle
        isAnimating = false
        nextAttackBonus = 0
        discoveryBonus = profile.shopDiscovery
        profile.shopPotions = 0
        profile.shopGoldBonus = 0
        profile.shopDiscovery = 0
        profile.shopGuard = 0
        profile.runs += 1
        hasResume = false
        clearCycle()
        saveProfile()
        phase = .running
        advanceToRoom()
    }

    func resumeRun() {
        guard let data = UserDefaults.standard.data(forKey: cycleKey), let snapshot = try? JSONDecoder().decode(CycleSnapshot.self, from: data) else {
            hasResume = false
            return
        }
        profile.selectedHero = snapshot.heroID
        profile.buildByHero[snapshot.heroID] = snapshot.build.rawValue
        runMode = snapshot.mode
        depth = snapshot.depth
        roomNumber = snapshot.roomNumber
        route = snapshot.route
        currentRoom = snapshot.currentRoom
        hp = snapshot.hp
        maxHP = snapshot.maxHP
        mp = snapshot.mp
        maxMP = snapshot.maxMP
        attack = snapshot.attack
        guardValue = snapshot.guardValue
        potions = snapshot.potions
        cycleGold = snapshot.gold
        goldMultiplier = snapshot.goldMultiplier
        currentEnemy = snapshot.enemy
        eventText = snapshot.eventText
        eventChoices = snapshot.eventChoices
        rewardChoices = snapshot.rewardChoices
        relics = snapshot.relics
        showNextButton = snapshot.showNextButton
        rewardChosen = snapshot.rewardChosen
        hasResume = false
        combatAnimation = .idle
        isAnimating = false
        phase = .running
        addLog("前回のサイクルを安全な地点から再開した。", tone: .good)
    }

    func abandonRun() {
        isAnimating = false
        clearCycle()
        phase = .home
        homeTab = .heroes
    }

    func returnToTitle() {
        isAnimating = false
        phase = .title
        currentEnemy = nil
        showNextButton = false
    }

    func advanceToRoom() {
        guard phase == .running, !route.isEmpty else { return }
        currentRoom = route[min(roomNumber - 1, route.count - 1)]
        combatAnimation = .idle
        isAnimating = false
        currentEnemy = nil
        eventChoices = []
        eventText = ""
        rewardChoices = []
        rewardChosen = false
        showNextButton = false
        rewardText = ""
        log = []
        profile.rooms += 1

        switch currentRoom {
        case .battle, .elite, .boss:
            currentEnemy = makeEnemy(for: currentRoom)
            addLog(currentRoom == .boss ? "虚ろの冠があなたの名前を呼んだ。" : "裂け目から新しい敵が現れた。", tone: .danger)
        case .event:
            let branch = (roomNumber + depth) % 3
            eventText = [
                "祠は過去の旅人が置いていった記憶を燃やしている。何を差し出す？",
                "沼の雨が一滴だけ止まった。止まった場所には別の未来が映っている。",
                "硝子の祭壇が、あなたの次の一撃を値踏みしている。"
            ][branch]
            eventChoices = eventChoicesFor(branch: branch)
        case .rest:
            eventText = "青い火が窪地に集まっている。短い休息は、鋭い刃より価値がある。"
        case .treasure:
            eventText = "真鍮の宝箱が灰の下でまだ温かい。開くなら今しかない。"
        }
        saveCycle()
    }

    func advanceFromRoom() {
        if currentRoom == .boss && roomNumber == route.count {
            finishVictory()
            return
        }
        if (currentRoom == .battle || currentRoom == .elite || currentRoom == .boss) && !rewardChosen { return }
        if (currentRoom == .event || currentRoom == .rest || currentRoom == .treasure) && !showNextButton { return }

        if runMode == .endless && currentRoom == .boss {
            depth += 1
            route = RouteCatalog.standard
            roomNumber = 1
        } else if roomNumber >= route.count {
            finishVictory()
            return
        } else {
            roomNumber += 1
        }
        advanceToRoom()
    }

    func normalAttack() {
        guard canAct, var enemy = currentEnemy else { return }
        startAnimation(.playerAttack)
        feedback(.attack)
        var damage = attack + Int.random(in: 0...6) + nextAttackBonus
        if relics.contains(where: { $0.id == "blood" }) { damage += 6 }
        nextAttackBonus = 0
        enemy.hp = max(0, enemy.hp - damage)
        currentEnemy = enemy
        addLog("通常攻撃。\(damage)ダメージ。", tone: .good)
        resolveAttack()
    }

    func useSkill(_ skill: HeroSkill) {
        guard canAct, mp >= skill.cost, var enemy = currentEnemy else {
            if mp < skill.cost { showToast("MPが足りません") }
            return
        }
        startAnimation(.skill)
        feedback(.skill)
        mp -= skill.cost
        var damage: Int
        switch skill.id {
        case "crescent": damage = 28; nextAttackBonus += 6
        case "flare": damage = 38
        case "shatter": damage = 32
        case "ward": damage = 16; guardValue += 16
        case "prayer": damage = 18; hp = min(maxHP, hp + 22)
        case "starfall": damage = 46
        case "riposte": damage = 34; nextAttackBonus += 10
        case "tide": damage = 34; hp = min(maxHP, hp + 32)
        case "undertow": damage = 42
        case "hex": damage = 45
        case "omen": damage = 24; nextAttackBonus += 10
        case "hammer": damage = 42; nextAttackBonus += 14
        case "bulwark": damage = 30; guardValue += 30; nextAttackBonus += 10
        case "fortress": damage = 30; guardValue += 38
        case "flash": damage = 36
        case "jackpot": damage = 27; cycleGold += 40
        case "null": damage = 50 + depth * 4
        case "echo": damage = 22; hp = min(maxHP, hp + 22); guardValue += 12
        case "temper": damage = 48 + relics.count * 2
        case "overclock": damage = 44
        case "focus": damage = 24; mp = min(maxMP, mp + (weeklyRule.contains("MP回復量半減") ? 3 : 6)); nextAttackBonus += 6
        case "ultimate": damage = 68; hp = min(maxHP, hp + 10); guardValue += 10
        default: damage = selectedHero.attack + 18
        }
        if selectedBuild == .arcane { damage = Int(Double(damage) * 1.12) }
        if relics.contains(where: { $0.id == "ember" }) { damage += 8 }
        enemy.hp = max(0, enemy.hp - damage)
        currentEnemy = enemy
        addLog("\(skill.name)。\(damage)ダメージ。", tone: .good)
        resolveAttack()
    }

    func guardAction() {
        guard canAct else { return }
        startAnimation(.playerAttack)
        feedback(.ward)
        guardValue += 18
        addLog("身構えた。守り+18。", tone: .good)
        queueEnemyTurn()
    }

    func drinkPotion() {
        guard canAct, potions > 0, hp < maxHP else { return }
        startAnimation(.heal)
        feedback(.heal)
        potions -= 1
        let healed = min(22 + (relics.contains(where: { $0.id == "tonic" }) ? 15 : 0), maxHP - hp)
        hp += healed
        addLog("トニックでHPが\(healed)回復。", tone: .good)
        queueEnemyTurn()
    }

    func chooseEvent(_ choice: EventChoice) {
        guard currentRoom == .event, !showNextButton else { return }
        switch choice.effect {
        case .heal:
            let healed = min(20, maxHP - hp)
            hp += healed
            mp = maxMP
            eventText = "記憶を預け、HP\(healed)とMPを取り戻した。"
        case .gold:
            hp = max(1, hp - 8)
            cycleGold += 70
            eventText = "未来を買い、HP8と引き換えに70Gを得た。"
        case .map:
            discoveryBonus += 1
            eventText = "道筋を読み、次の遺物候補を増やした。"
        case .guardBoost:
            guardValue += 24
            nextAttackBonus += 24
            eventText = "祭壇の力が次の攻撃と守りへ宿った。"
        case .drink:
            let healed = min(12, maxHP - hp)
            hp += healed
            guardValue += 12
            eventText = "雨を飲み、HP\(healed)回復・守り+12。"
        case .curse:
            profile.fragments += 25
            hp = max(1, hp - 8)
            eventText = "沼の印を受け、欠片25と呪いを得た。"
        case .mastery:
            profile.mastery[selectedHero.id, default: 0] += 2
            hp = min(maxHP, hp + 8)
            eventText = "名前を取り戻し、習熟+2。"
        }
        showNextButton = true
        addLog(eventText, tone: choice.effect == .curse ? .danger : .good)
        feedback(choice.effect == .curse ? .enemy : .reward)
        saveCycle()
    }

    func rest() {
        guard currentRoom == .rest, !showNextButton else { return }
        let healed = min((ruleText.contains("休息") ? 24 : 32), maxHP - hp)
        hp += healed
        guardValue += 12
        mp = min(maxMP, mp + (weeklyRule.contains("MP回復量半減") ? 3 : 6))
        eventText = "灯りの窪地でHP\(healed)回復。守り+12、MP+6。"
        showNextButton = true
        addLog(eventText, tone: .good)
        feedback(.heal)
        saveCycle()
    }

    func openTreasure() {
        guard currentRoom == .treasure, !showNextButton else { return }
        let found = Int(Double(65) * goldMultiplier)
        cycleGold += found
        potions += 1
        guardValue += 8
        eventText = "宝物庫から\(found)Gとトニックを得た。"
        rewardText = "+\(found)G"
        showNextButton = true
        addLog(eventText, tone: .rare)
        feedback(.reward)
        saveCycle()
    }

    func chooseRelic(_ relic: Relic) {
        guard showNextButton, !rewardChosen else { return }
        rewardChosen = true
        relics.append(relic)
        attack += relic.attackBonus
        maxHP += relic.hpBonus
        hp += relic.hpBonus
        maxMP += relic.mpBonus
        mp += relic.mpBonus
        guardValue += relic.guardBonus
        goldMultiplier += relic.goldBonus
        rewardText = "遺物「\(relic.name)」を装備中"
        addLog("遺物「\(relic.name)」を選んだ。", tone: .rare)
        feedback(.reward)
        saveCycle()
    }

    func selectHero(_ hero: Hero) {
        guard profile.unlockedHeroes.contains(hero.id) else {
            if profile.gold >= hero.cost {
                profile.gold -= hero.cost
                profile.unlockedHeroes.append(hero.id)
                profile.mastery[hero.id] = 0
                showToast("\(hero.name)を解放しました")
                saveProfile()
            } else {
                showToast("ゴールドが足りません")
            }
            return
        }
        profile.selectedHero = hero.id
        saveProfile()
        objectWillChange.send()
    }

    func selectBuild(_ build: BuildType, for hero: Hero) {
        guard profile.unlockedHeroes.contains(hero.id) else { return }
        profile.buildByHero[hero.id] = build.rawValue
        saveProfile()
        objectWillChange.send()
    }

    func buyUpgrade(_ definition: UpgradeDefinition) {
        let level = upgrade(definition.id)
        guard level < definition.maximum else { return }
        let price = definition.baseCost + level * (definition.baseCost / 2)
        guard profile.gold >= price else { showToast("ゴールドが足りません"); return }
        profile.gold -= price
        profile.upgrades[definition.id] = level + 1
        saveProfile()
    }

    func buyShopItem(_ item: ShopItem) {
        guard profile.gold >= item.price else { showToast("ゴールドが足りません"); return }
        profile.gold -= item.price
        switch item.id {
        case "tonic": profile.shopPotions += 1
        case "map": profile.shopDiscovery += 1
        case "fortune": profile.shopGoldBonus += 0.15
        case "ward": profile.shopGuard += 20
        case "echo": profile.rebirths += 1
        default: break
        }
        saveProfile()
        showToast("\(item.name)を購入しました")
    }

    func summonHero() {
        guard profile.gold >= 160 else { showToast("ゴールドが足りません"); return }
        profile.gold -= 160
        let locked = Hero.catalog.filter { !profile.unlockedHeroes.contains($0.id) }
        if let hero = locked.randomElement() {
            profile.unlockedHeroes.append(hero.id)
            profile.mastery[hero.id] = 0
            showToast("\(hero.name)を召喚しました")
        } else {
            profile.fragments += 40
            showToast("重複召喚。欠片+40")
        }
        saveProfile()
    }

    func performRebirth() {
        guard profile.depth >= 10 || profile.rebirths > 0 else { showToast("深度10到達後に解放されます"); return }
        profile.rebirths += max(1, profile.depth / 10)
        profile.depth = 0
        profile.gold = 0
        for key in profile.upgrades.keys { profile.upgrades[key] = (profile.upgrades[key] ?? 0) / 2 }
        saveProfile()
        showToast("輪廻しました。残響を得ました")
    }

    func toggleSetting(_ keyPath: WritableKeyPath<SettingsState, Bool>) {
        var settings = profile.settings
        settings[keyPath: keyPath].toggle()
        profile.settings = settings
        saveProfile()
    }

    func setSetting(_ keyPath: WritableKeyPath<SettingsState, Bool>, value: Bool) {
        var settings = profile.settings
        settings[keyPath: keyPath] = value
        profile.settings = settings
        saveProfile()
    }

    var ruleText: String {
        if runMode == .weekly { return weeklyRule }
        if runMode == .daily { return "今日の深度規則" }
        return depthRules[depth % depthRules.count]
    }

    private var weeklyRule: String {
        let rules = ["全敵のHP+20%・遺物候補+1", "MP回復量半減・ゴールド+40%", "ポーションなし・開始時に守り+30", "通常攻撃の次に敵が強化・習熟+50%"]
        let week = Int(Date().timeIntervalSince1970 / 604800)
        return rules[abs(week) % rules.count]
    }

    private let depthRules = ["標準規則", "敵は初手に守りを得る", "休息の回復量-25%", "エリート出現率上昇", "敵のHP+12%", "敵の攻撃+8%", "遺物候補が呪われる"]

    private var canAct: Bool {
        phase == .running && !isAnimating && (currentRoom == .battle || currentRoom == .elite || currentRoom == .boss) && !showNextButton && currentEnemy != nil
    }

    private func eventChoicesFor(branch: Int) -> [EventChoice] {
        switch branch {
        case 0:
            return [EventChoice(id: "heal", title: "記憶を預ける", detail: "HP20回復・MP全回復", icon: "heart.fill", effect: .heal), EventChoice(id: "gold", title: "未来を買う", detail: "HP8を失い70G", icon: "circle.fill", effect: .gold), EventChoice(id: "map", title: "道筋を読む", detail: "遺物候補+1", icon: "map.fill", effect: .map)]
        case 1:
            return [EventChoice(id: "drink", title: "雨を飲む", detail: "HP12回復・守り+12", icon: "drop.fill", effect: .drink), EventChoice(id: "curse", title: "沼の印を受ける", detail: "欠片+25・代償あり", icon: "moon.fill", effect: .curse), EventChoice(id: "mastery", title: "名前を返す", detail: "習熟+2・HP8回復", icon: "person.fill", effect: .mastery)]
        default:
            return [EventChoice(id: "map", title: "祭壇に触れる", detail: "遺物候補+1", icon: "diamond.fill", effect: .map), EventChoice(id: "power", title: "力を借りる", detail: "次の攻撃+24・守り+24", icon: "bolt.fill", effect: .guardBoost), EventChoice(id: "gold", title: "HPを捧げる", detail: "HP8を失い70G", icon: "flame.fill", effect: .gold)]
        }
    }

    private func resolveAttack() {
        guard let enemy = currentEnemy else { return }
        if enemy.hp > 0 {
            queueEnemyTurn()
            return
        }
        let found = Int(Double(enemy.reward) * goldMultiplier)
        cycleGold += found
        profile.kills += 1
        if !profile.defeatedEnemyIDs.contains(enemy.id) { profile.defeatedEnemyIDs.append(enemy.id) }
        profile.mastery[selectedHero.id, default: 0] += 1
        if enemy.isBoss && roomNumber == route.count && runMode != .endless {
            finishVictory()
            return
        }
        isAnimating = false
        rewardChoices = relicPool()
        rewardText = "+\(found)G"
        rewardChosen = false
        showNextButton = true
        addLog("\(enemy.name)を倒した。+\(found)G", tone: .rare)
        saveProfile()
        saveCycle()
    }

    private func queueEnemyTurn() {
        guard phase == .running else { return }
        isAnimating = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.38) { [weak self] in
            self?.performEnemyTurn()
        }
    }

    private func performEnemyTurn() {
        guard let enemy = currentEnemy, enemy.hp > 0 else { return }
        startAnimation(.enemyAttack)
        feedback(.enemy)
        var rawDamage = Int.random(in: enemy.attack)
        if runMode == .weekly && weeklyRule.contains("通常攻撃") { rawDamage = Int(Double(rawDamage) * 1.25) }
        if ruleText.contains("敵の攻撃+8%") { rawDamage = Int(Double(rawDamage) * 1.08) }
        let blocked = min(guardValue, rawDamage)
        guardValue -= blocked
        let damage = rawDamage - blocked
        hp = max(0, hp - damage)
        if blocked > 0 { addLog("守りが\(blocked)ダメージを吸収した。", tone: .good) }
        if damage > 0 { addLog("\(enemy.name)の攻撃。\(damage)ダメージ。", tone: .danger) }
        if currentRoom == .boss && mp > 0 { mp = max(0, mp - 2) }
        if hp <= 0 {
            isAnimating = false
            phase = .defeated
            bankRun(win: false)
        } else {
            saveCycle()
            let token = animationToken
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.42) { [weak self] in
                guard let self, self.animationToken == token, self.phase == .running else { return }
                self.combatAnimation = .idle
                self.isAnimating = false
            }
        }
    }

    private func makeEnemy(for room: RoomKind) -> Enemy {
        let scale = 1.0 + Double(depth) * 0.09 + Double(max(roomNumber - 1, 0)) * 0.055
        if room == .boss {
            let base = Enemy.bosses[(depth + roomNumber) % Enemy.bosses.count]
            return scaledEnemy(base, multiplier: scale * (ruleText.contains("敵のHP+12%") ? 1.12 : 1.0))
        }
        let region = currentAreaIndex
        let regional = Enemy.catalog.filter { $0.area == region || $0.area == 0 }
        let eligible = room == .elite ? regional.filter { $0.maxHP >= 120 } : regional
        let base = (eligible.isEmpty ? Enemy.catalog : eligible).randomElement() ?? Enemy.catalog[0]
        return scaledEnemy(base, multiplier: scale * (runMode == .weekly && weeklyRule.contains("HP+20%") ? 1.2 : 1.0))
    }

    private func scaledEnemy(_ base: Enemy, multiplier: Double) -> Enemy {
        let health = max(1, Int(Double(base.maxHP) * multiplier))
        return Enemy(id: base.id, name: base.name, description: base.description, imageName: base.imageName, maxHP: health, attack: base.attack, reward: base.reward, intent: base.intent, area: base.area, isBoss: base.isBoss)
    }

    private func relicPool() -> [Relic] {
        let count = min(4, 2 + upgrade("discovery") + discoveryBonus + (runMode == .weekly && weeklyRule.contains("候補+1") ? 1 : 0))
        return Array(Relic.catalog.shuffled().prefix(count))
    }

    private func finishVictory() {
        isAnimating = false
        combatAnimation = .victory
        feedback(.victory)
        phase = .victory
        showNextButton = false
        bankRun(win: true)
    }

    private func bankRun(win: Bool) {
        if !win { feedback(.defeat) }
        profile.gold += cycleGold
        profile.mastery[selectedHero.id, default: 0] += win ? (runMode == .weekly ? 5 : 3) : 1
        if win {
            profile.wins += 1
            profile.depth = max(profile.depth, depth + 1)
            if runMode == .weekly { profile.weeklyWins += 1 }
            if runMode == .endless { profile.endlessBest = max(profile.endlessBest, depth) }
        }
        clearCycle()
        saveProfile()
    }

    private func routeFor(_ mode: RunMode) -> [RoomKind] {
        switch mode {
        case .deep: return RouteCatalog.deep
        case .bossRush: return RouteCatalog.bossRush
        default: return RouteCatalog.standard
        }
    }

    private func upgrade(_ id: String) -> Int { profile.upgrades[id] ?? 0 }

    func upgradeLevel(_ id: String) -> Int { upgrade(id) }

    func upgradeCost(_ definition: UpgradeDefinition) -> Int {
        definition.baseCost + upgrade(definition.id) * (definition.baseCost / 2)
    }

    private func normalizeProfile() {
        if profile.unlockedHeroes.isEmpty { profile.unlockedHeroes = ["wanderer"] }
        if !profile.unlockedHeroes.contains(profile.selectedHero) { profile.selectedHero = profile.unlockedHeroes[0] }
        for hero in Hero.catalog {
            profile.buildByHero[hero.id] = profile.buildByHero[hero.id] ?? BuildType.balanced.rawValue
            profile.mastery[hero.id] = profile.mastery[hero.id] ?? 0
        }
        for definition in UpgradeCatalog.all { profile.upgrades[definition.id] = profile.upgrades[definition.id] ?? 0 }
    }

    private func saveProfile() {
        guard let data = try? JSONEncoder().encode(profile) else { return }
        UserDefaults.standard.set(data, forKey: profileKey)
        objectWillChange.send()
    }

    private func saveCycle() {
        guard phase == .running else { return }
        let snapshot = CycleSnapshot(heroID: selectedHero.id, build: selectedBuild, mode: runMode, depth: depth, roomNumber: roomNumber, route: route, currentRoom: currentRoom, hp: hp, maxHP: maxHP, mp: mp, maxMP: maxMP, attack: attack, guardValue: guardValue, potions: potions, gold: cycleGold, goldMultiplier: goldMultiplier, enemy: currentEnemy, eventText: eventText, eventChoices: eventChoices, rewardChoices: rewardChoices, relics: relics, showNextButton: showNextButton, rewardChosen: rewardChosen)
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        UserDefaults.standard.set(data, forKey: cycleKey)
        hasResume = true
    }

    private func clearCycle() {
        UserDefaults.standard.removeObject(forKey: cycleKey)
        hasResume = false
    }

    private static func loadProfile(key: String) -> ProfileState {
        guard let data = UserDefaults.standard.data(forKey: key), let loaded = try? JSONDecoder().decode(ProfileState.self, from: data) else { return ProfileState() }
        return loaded
    }

    private func showToast(_ message: String) {
        toast = message
    }

    private func addLog(_ text: String, tone: LogTone) {
        log.insert(CombatLogEntry(text: text, tone: tone), at: 0)
        if log.count > 8 { log.removeLast() }
    }

    private func startAnimation(_ animation: CombatAnimation) {
        animationToken += 1
        combatAnimation = animation
    }

    private func feedback(_ kind: RiftboundFeedbackKind) {
        RiftboundFeedback.shared.play(kind, soundEnabled: profile.settings.sound, vibrationEnabled: profile.settings.vibration)
    }
}
