import Foundation
import SwiftUI

enum GamePhase: String {
    case title
    case home
    case running
    case victory
    case defeated
}

enum HomeTab: String, CaseIterable {
    case heroes = "主人公"
    case tree = "ツリー"
    case shop = "商店"
    case gacha = "召喚"
    case challenges = "挑戦"
    case codex = "図鑑"
    case settings = "設定"
}

enum RunMode: String, Codable, CaseIterable {
    case standard
    case deep
    case daily
    case weekly
    case bossRush
    case endless

    var title: String {
        switch self {
        case .standard: return "通常サイクル"
        case .deep: return "深層サイクル"
        case .daily: return "デイリー挑戦"
        case .weekly: return "ウィークリー契約"
        case .bossRush: return "ボス連戦"
        case .endless: return "エンドレス"
        }
    }
}

enum BuildType: String, Codable, CaseIterable {
    case balanced
    case assault
    case guardian
    case arcane

    var title: String {
        switch self {
        case .balanced: return "均衡構成"
        case .assault: return "猛攻構成"
        case .guardian: return "守護構成"
        case .arcane: return "術式構成"
        }
    }

    var detail: String {
        switch self {
        case .balanced: return "HP・MP・攻撃を安定させる"
        case .assault: return "攻撃+4、最大HP-8"
        case .guardian: return "最大HP+22、開始守り+8"
        case .arcane: return "MP+10、スキル威力+12%"
        }
    }

    var hp: Int { self == .assault ? -8 : self == .guardian ? 22 : self == .arcane ? -4 : 0 }
    var mp: Int { self == .guardian ? -4 : self == .arcane ? 10 : 0 }
    var attack: Int { self == .assault ? 4 : self == .guardian ? -1 : 0 }
    var startingGuard: Int { self == .guardian ? 8 : 0 }
}

enum RoomKind: String, Codable, CaseIterable, Identifiable {
    case battle
    case event
    case rest
    case treasure
    case elite
    case boss

    var id: String { rawValue }

    var title: String {
        switch self {
        case .battle: return "ヴェイルボーンの襲撃"
        case .event: return "耳を澄ます祠"
        case .rest: return "灯りの窪地"
        case .treasure: return "開かれた宝物庫"
        case .elite: return "エリートの巣"
        case .boss: return "虚ろの冠"
        }
    }

    var subtitle: String {
        switch self {
        case .battle: return "闇の中で、足音を聞いたものがいる。"
        case .event: return "祠は、あなたの次の一手を知っている。"
        case .rest: return "青い火のそばでは、傷も少しだけ静かになる。"
        case .treasure: return "古い錠前は、あなたを待っていた。"
        case .elite: return "濃い裂け目が、強い個体を呼び寄せる。"
        case .boss: return "すべての裂け目には心臓がある。これは牙を持つ。"
        }
    }

    var icon: String {
        switch self {
        case .battle: return "bolt.fill"
        case .event: return "eye.fill"
        case .rest: return "flame.fill"
        case .treasure: return "shippingbox.fill"
        case .elite: return "diamond.fill"
        case .boss: return "crown.fill"
        }
    }

    var badge: String {
        switch self {
        case .battle: return "COMBAT"
        case .event: return "OMEN"
        case .rest: return "REST"
        case .treasure: return "RELIC"
        case .elite: return "ELITE"
        case .boss: return "THE HEART"
        }
    }

    var tint: Color {
        switch self {
        case .battle: return RiftboundTheme.ember
        case .event: return RiftboundTheme.lilac
        case .rest: return RiftboundTheme.mint
        case .treasure: return RiftboundTheme.gold
        case .elite: return RiftboundTheme.blue
        case .boss: return RiftboundTheme.crimson
        }
    }
}

enum RouteCatalog {
    static let standard: [RoomKind] = [.battle, .event, .battle, .rest, .elite, .treasure, .battle, .event, .elite, .rest, .battle, .treasure, .boss]
    static let deep: [RoomKind] = standard + standard
    static let bossRush: [RoomKind] = [.battle, .boss, .rest, .boss, .treasure, .boss]
}

struct HeroSkill: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let cost: Int
    let detail: String
    let icon: String
}

struct Hero: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let role: String
    let description: String
    let icon: String
    let maxHP: Int
    let maxMP: Int
    let attack: Int
    let cost: Int
    let skills: [HeroSkill]

    var allSkills: [HeroSkill] { skills + Self.commonSkills }

    static let commonSkills = [
        HeroSkill(id: "focus", name: "集中の型", cost: 4, detail: "24ダメージ。MP6回復、次の攻撃+6。", icon: "scope"),
        HeroSkill(id: "ultimate", name: "裂け目奥義", cost: 14, detail: "68ダメージ。HP10回復、守り+10。", icon: "sparkles")
    ]

    static let catalog: [Hero] = [
        Hero(id: "wanderer", name: "蒼影の旅人", role: "均衡", description: "通常攻撃と守りを使い分ける最初の一人。", icon: "figure.walk", maxHP: 100, maxMP: 24, attack: 14, cost: 0, skills: [HeroSkill(id: "crescent", name: "月影の連撃", cost: 5, detail: "28ダメージ。次の通常攻撃+6。", icon: "moon.stars"), HeroSkill(id: "ward", name: "虚ろの守り", cost: 7, detail: "守り+16。", icon: "shield.fill")]),
        Hero(id: "oracle", name: "灰祈の巫女", role: "術式", description: "MPが多く、炎上と回復を循環させる術士。", icon: "wand.and.stars", maxHP: 82, maxMP: 42, attack: 11, cost: 420, skills: [HeroSkill(id: "flare", name: "灰灯の奔流", cost: 8, detail: "38ダメージ。", icon: "flame.fill"), HeroSkill(id: "prayer", name: "灰の祈り", cost: 10, detail: "18ダメージ、HP22回復。", icon: "heart.fill")]),
        Hero(id: "warden", name: "硝子守", role: "守護", description: "高いHPと反撃で深度が上がるほど強くなる。", icon: "shield.lefthalf.filled", maxHP: 128, maxMP: 18, attack: 12, cost: 680, skills: [HeroSkill(id: "shatter", name: "硝子砕き", cost: 4, detail: "32ダメージ。", icon: "circle.hexagongrid.fill"), HeroSkill(id: "bulwark", name: "城塞の構え", cost: 6, detail: "守り+30、次の攻撃+10。", icon: "building.columns.fill")]),
        Hero(id: "riftblade", name: "裂星の剣士", role: "連撃", description: "低い防御を手数と会心で押し切る剣士。", icon: "figure.fencing", maxHP: 94, maxMP: 28, attack: 16, cost: 820, skills: [HeroSkill(id: "starfall", name: "星落とし", cost: 6, detail: "46ダメージ。", icon: "star.fill"), HeroSkill(id: "riposte", name: "返し星", cost: 8, detail: "34ダメージ、次の攻撃+10。", icon: "arrow.uturn.left")]),
        Hero(id: "tidekeeper", name: "潮祈の番人", role: "回復", description: "回復を攻撃へ変える長期戦向けの守り手。", icon: "water.waves", maxHP: 108, maxMP: 36, attack: 10, cost: 980, skills: [HeroSkill(id: "tide", name: "青潮の槍", cost: 7, detail: "34ダメージ、HP32回復。", icon: "water.waves"), HeroSkill(id: "undertow", name: "引き潮", cost: 9, detail: "42ダメージ。", icon: "arrow.down")]),
        Hero(id: "mothseer", name: "蛾灯の予言者", role: "呪術", description: "敵へ呪いを積み、スキルを連発する予言者。", icon: "eye.trianglebadge.exclamationmark", maxHP: 76, maxMP: 48, attack: 9, cost: 1150, skills: [HeroSkill(id: "hex", name: "黒い予言", cost: 9, detail: "45ダメージ。", icon: "moon.fill"), HeroSkill(id: "omen", name: "凶兆の眼", cost: 5, detail: "24ダメージ、次の攻撃+10。", icon: "eye.fill")]),
        Hero(id: "ironbound", name: "黒鉄の巨兵", role: "反撃", description: "受けて耐え、守りを反撃へ変える巨兵。", icon: "hammer.fill", maxHP: 150, maxMP: 14, attack: 13, cost: 1350, skills: [HeroSkill(id: "hammer", name: "黒鉄の杭", cost: 4, detail: "42ダメージ。", icon: "hammer.fill"), HeroSkill(id: "fortress", name: "歩く要塞", cost: 5, detail: "守り+38。", icon: "lock.shield.fill")]),
        Hero(id: "veilrunner", name: "ヴェイル走り", role: "幸運", description: "ゴールドと遺物を増やし危険を速度で抜ける。", icon: "figure.run", maxHP: 90, maxMP: 30, attack: 13, cost: 1600, skills: [HeroSkill(id: "flash", name: "閃歩", cost: 4, detail: "36ダメージ。", icon: "bolt.fill"), HeroSkill(id: "jackpot", name: "裂け目の大当たり", cost: 10, detail: "27ダメージ、40G追加。", icon: "dollarsign.circle.fill")]),
        Hero(id: "crownless", name: "無冠の剥片", role: "深度", description: "深度が高いほど能力が伸びる冠の残響。", icon: "circle.dashed", maxHP: 112, maxMP: 26, attack: 15, cost: 2000, skills: [HeroSkill(id: "null", name: "無名の断絶", cost: 8, detail: "深度に応じて威力上昇。", icon: "nosign"), HeroSkill(id: "echo", name: "残響の王座", cost: 7, detail: "HP22回復、守り+12。", icon: "crown.fill")]),
        Hero(id: "dawnsmith", name: "夜明け鍛冶", role: "工匠", description: "遺物を改造し、ひとつのビルドを磨く工匠。", icon: "wrench.and.screwdriver.fill", maxHP: 120, maxMP: 22, attack: 14, cost: 2400, skills: [HeroSkill(id: "temper", name: "鍛造一閃", cost: 5, detail: "48ダメージ。", icon: "wrench.and.screwdriver.fill"), HeroSkill(id: "overclock", name: "過熱炉", cost: 11, detail: "44ダメージ。", icon: "gauge.with.dots.needle.67percent")])
    ]
}

struct Enemy: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let description: String
    let imageName: String
    let maxHP: Int
    var hp: Int
    let attack: ClosedRange<Int>
    let reward: Int
    let intent: String
    let area: Int
    let isBoss: Bool

    init(id: String, name: String, description: String, imageName: String = "enemy", maxHP: Int, attack: ClosedRange<Int>, reward: Int, intent: String, area: Int = 0, isBoss: Bool = false) {
        self.id = id
        self.name = name
        self.description = description
        self.imageName = imageName
        self.maxHP = maxHP
        self.hp = maxHP
        self.attack = attack
        self.reward = reward
        self.intent = intent
        self.area = area
        self.isBoss = isBoss
    }

    static let catalog: [Enemy] = [
        Enemy(id: "wisp", name: "灯火のウィスプ", description: "空腹の青い灯がMPの匂いを嗅ぎつける。", imageName: "enemy-wisp", maxHP: 68, attack: 8...13, reward: 34, intent: "MPを吸う一撃"),
        Enemy(id: "hound", name: "沼喰らい", description: "恐怖が鎧の下にあることを知っている。", imageName: "enemy-hound", maxHP: 82, attack: 10...16, reward: 42, intent: "出血する爪"),
        Enemy(id: "glass", name: "硝子騎士", description: "剣が鳴ったときには、もう遅い。", imageName: "enemy-glass", maxHP: 96, attack: 11...18, reward: 52, intent: "反射の斬撃"),
        Enemy(id: "shade", name: "裂け目の影", description: "倒した敵の輪郭だけを借りて歩く。", maxHP: 108, attack: 12...19, reward: 62, intent: "最大HPを削る闇"),
        Enemy(id: "ember", name: "灰炎の蛾", description: "燃え尽きるまで回復の道を塞ぐ。", imageName: "enemy-wisp", maxHP: 116, attack: 13...21, reward: 72, intent: "回復阻害の炎"),
        Enemy(id: "sentinel", name: "鏡面の番人", description: "受けた力を冷たい光に変えて返す。", imageName: "enemy-glass", maxHP: 132, attack: 14...23, reward: 84, intent: "守りを砕く一撃"),
        Enemy(id: "ashwing", name: "灰翼の蛾", description: "羽ばたくたび回復できない灰が降る。", imageName: "enemy-ashwing", maxHP: 104, attack: 12...20, reward: 70, intent: "回復阻害の粉", area: 1),
        Enemy(id: "riftback", name: "裂背の巨獣", description: "胸の裂け目に古いサイクルを飼っている。", imageName: "enemy-riftback", maxHP: 168, attack: 16...25, reward: 105, intent: "重い踏みつけ", area: 1),
        Enemy(id: "bogseer", name: "沼の観測者", description: "水面に映った未来を先に攻撃してくる。", imageName: "enemy-wisp", maxHP: 122, attack: 13...22, reward: 78, intent: "予告の反転", area: 1),
        Enemy(id: "mossknight", name: "苔鎧の騎士", description: "濡れた鎧が傷を塞ぎ距離を詰める。", imageName: "enemy-hound", maxHP: 145, attack: 15...24, reward: 92, intent: "自己回復", area: 1),
        Enemy(id: "rainwidow", name: "青雨の蜘蛛", description: "糸に触れたMPが雨の中へ流れ出す。", imageName: "enemy-wisp", maxHP: 118, attack: 14...21, reward: 80, intent: "MP吸収", area: 1),
        Enemy(id: "glassbeetle", name: "硝子甲虫", description: "甲殻のすべてがこちらの攻撃を覚えている。", imageName: "enemy-glass", maxHP: 138, attack: 15...23, reward: 98, intent: "反射殻", area: 2),
        Enemy(id: "prismarcher", name: "プリズム弓兵", description: "矢が別の角度からもう一度来る。", imageName: "enemy-glass", maxHP: 126, attack: 17...25, reward: 100, intent: "二重射撃", area: 2),
        Enemy(id: "mirrorling", name: "鏡写し", description: "一番高い能力を一時的に借りる。", imageName: "enemy-glass", maxHP: 112, attack: 14...24, reward: 90, intent: "能力コピー", area: 2),
        Enemy(id: "violetfang", name: "紫牙の獣", description: "硝子の床を走る影だけの捕食者。", imageName: "enemy-hound", maxHP: 152, attack: 18...27, reward: 112, intent: "会心の牙", area: 2),
        Enemy(id: "shardmonk", name: "欠片僧", description: "祈りのたび受けた傷を敵へ返す。", imageName: "enemy-wisp", maxHP: 136, attack: 16...26, reward: 105, intent: "反射の祈り", area: 2),
        Enemy(id: "crownling", name: "冠の幼体", description: "虚ろの冠からこぼれた小さな王の記憶。", maxHP: 148, attack: 18...27, reward: 120, intent: "冠の命令", area: 3),
        Enemy(id: "astralhound", name: "星喰らいの猟犬", description: "星明かりを食べ道を暗くする。", imageName: "enemy-riftback", maxHP: 172, attack: 19...29, reward: 135, intent: "視界封鎖", area: 3),
        Enemy(id: "nullhand", name: "無手の処刑人", description: "武器を持たない手が最も重い一撃を落とす。", imageName: "enemy-ashwing", maxHP: 160, attack: 20...31, reward: 145, intent: "守り無視", area: 3),
        Enemy(id: "hollowpriest", name: "空洞の司祭", description: "倒れるたび別の敵のHPを満たす。", imageName: "enemy-wisp", maxHP: 155, attack: 18...28, reward: 138, intent: "敵全体回復", area: 3),
        Enemy(id: "redveil", name: "赤いヴェイル", description: "攻撃の瞬間だけ輪郭を持つ敵意。", maxHP: 130, attack: 21...30, reward: 130, intent: "不可視の一撃", area: 3),
        Enemy(id: "starvedguard", name: "飢えた護衛", description: "冠の前に立ち誰の名前も通さない。", imageName: "enemy-glass", maxHP: 190, attack: 20...32, reward: 160, intent: "深度強化", area: 3),
        Enemy(id: "blackcomet", name: "黒い彗星", description: "落ちるだけでエリアのルールを書き換える。", imageName: "enemy-ashwing", maxHP: 180, attack: 22...34, reward: 170, intent: "ルール破壊", area: 3),
        Enemy(id: "veiloracle", name: "ヴェイルの予言獣", description: "出現の結果を先読みしスキルMPを奪う。", imageName: "enemy-ashwing", maxHP: 172, attack: 21...32, reward: 180, intent: "MP反転", area: 3),
        Enemy(id: "prismmantis", name: "プリズムマンティス", description: "宝石の鎌で守りと遺物の輝きを切り裂く。", imageName: "enemy-prism-mantis", maxHP: 184, attack: 22...33, reward: 195, intent: "守り反転", area: 2),
        Enemy(id: "voidherald", name: "虚無の告知者", description: "裂け目の未来を読み次のスキルを弱める。", imageName: "enemy-void-herald", maxHP: 176, attack: 20...35, reward: 205, intent: "MP封印", area: 3)
    ]

    static let bosses: [Enemy] = [
        Enemy(id: "crown", name: "虚ろの冠", description: "千回の敗北の記憶をまとった王のない王。", maxHP: 260, attack: 18...27, reward: 260, intent: "冠の一撃・守り破壊", isBoss: true),
        Enemy(id: "astral", name: "飢えた星体", description: "星を食べ終えた処刑人。", imageName: "boss-astral", maxHP: 310, attack: 20...30, reward: 310, intent: "星喰らい", isBoss: true),
        Enemy(id: "mirequeen", name: "沼母の女王", description: "青い雨を産み回復の意味を奪う。", imageName: "enemy-riftback", maxHP: 340, attack: 21...31, reward: 340, intent: "回復反転", isBoss: true),
        Enemy(id: "glassregent", name: "硝子の摂政", description: "割れる前の世界を鏡の奥から見張る。", imageName: "enemy-glass", maxHP: 360, attack: 22...33, reward: 360, intent: "反射王座", isBoss: true),
        Enemy(id: "ashmother", name: "灰翼の母", description: "無数の蛾を羽ばたかせ全てを灰に戻す。", imageName: "enemy-ashwing", maxHP: 380, attack: 24...34, reward: 380, intent: "灰の雨", isBoss: true),
        Enemy(id: "chaincolossus", name: "鎖の巨神", description: "裂け目そのものを鎖で引きずる守護者。", imageName: "enemy-riftback", maxHP: 420, attack: 24...36, reward: 420, intent: "大地震", isBoss: true),
        Enemy(id: "crownbeast", name: "冠喰らい", description: "王を喰らった獣。", imageName: "enemy-hound", maxHP: 450, attack: 26...38, reward: 450, intent: "最大HP捕食", isBoss: true),
        Enemy(id: "lastveil", name: "最後のヴェイル", description: "全ての敵の影を束ねた深度の終端。", imageName: "boss-astral", maxHP: 500, attack: 28...42, reward: 500, intent: "終端の宣告", isBoss: true),
        Enemy(id: "mirrordragon", name: "鏡晶竜ミラージュ", description: "無数の敗北を反射する最終捕食者。", imageName: "boss-mirror-dragon", maxHP: 560, attack: 30...44, reward: 560, intent: "反射終焉", isBoss: true)
    ]
}

enum EventEffect: String, Codable {
    case heal
    case gold
    case map
    case guardBoost
    case drink
    case curse
    case mastery
}

struct EventChoice: Identifiable, Codable, Hashable {
    let id: String
    let title: String
    let detail: String
    let icon: String
    let effect: EventEffect
}

struct Relic: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let detail: String
    let tag: String
    let attackBonus: Int
    let hpBonus: Int
    let mpBonus: Int
    let goldBonus: Double
    let guardBonus: Int

    static let catalog: [Relic] = [
        Relic(id: "iron", name: "黒鉄の心臓", detail: "最大HP+18。", tag: "生命", attackBonus: 0, hpBonus: 18, mpBonus: 0, goldBonus: 0, guardBonus: 0),
        Relic(id: "moon", name: "月蝕の欠片", detail: "最大MP+8。", tag: "魔力", attackBonus: 0, hpBonus: 0, mpBonus: 8, goldBonus: 0, guardBonus: 0),
        Relic(id: "blood", name: "赤い糸", detail: "通常攻撃+6。", tag: "出血", attackBonus: 6, hpBonus: 0, mpBonus: 0, goldBonus: 0, guardBonus: 0),
        Relic(id: "coin", name: "金脈の指輪", detail: "獲得ゴールド+25%。", tag: "黄金", attackBonus: 0, hpBonus: 0, mpBonus: 0, goldBonus: 0.25, guardBonus: 0),
        Relic(id: "thorn", name: "棘の聖句", detail: "守り中に反撃+10。", tag: "守り", attackBonus: 0, hpBonus: 0, mpBonus: 0, goldBonus: 0, guardBonus: 3),
        Relic(id: "ember", name: "残火の芯", detail: "スキル威力+8。", tag: "炎上", attackBonus: 8, hpBonus: 0, mpBonus: 0, goldBonus: 0, guardBonus: 0)
    ] + (0..<74).map { index in
        let families = [("深紅の欠片", "出血"), ("潮騒の鈴", "魔力"), ("黒曜の羽", "攻撃"), ("空白の硬貨", "黄金"), ("霧の小瓶", "回復"), ("折れた星図", "探索"), ("鏡面の針", "反射"), ("冠の歯車", "深度")]
        let family = families[index % families.count]
        return Relic(id: "relic-\(index + 7)", name: "\(family.0) \(String(format: "%02d", index + 1))", detail: "\(family.1)系統の追加効果。", tag: family.1, attackBonus: index % 8 == 0 ? 2 : 0, hpBonus: index % 8 == 3 ? 4 : 0, mpBonus: index % 8 == 1 ? 2 : 0, goldBonus: index % 8 == 2 ? 0.04 : 0, guardBonus: index % 8 == 6 ? 3 : 0)
    }
}

struct UpgradeDefinition: Identifiable {
    let id: String
    let name: String
    let detail: String
    let baseCost: Int
    let maximum: Int
}

enum UpgradeCatalog {
    static let all: [UpgradeDefinition] = [
        UpgradeDefinition(id: "might", name: "裂傷の系譜", detail: "永続攻撃力+3。", baseCost: 70, maximum: 10),
        UpgradeDefinition(id: "vitality", name: "生還の系譜", detail: "永続最大HP+10。", baseCost: 80, maximum: 10),
        UpgradeDefinition(id: "arcana", name: "魔力の系譜", detail: "永続最大MP+4。", baseCost: 90, maximum: 10),
        UpgradeDefinition(id: "fortune", name: "黄金の系譜", detail: "永続ゴールド倍率+8%。", baseCost: 110, maximum: 8),
        UpgradeDefinition(id: "discovery", name: "探索の系譜", detail: "遺物候補を増やす。", baseCost: 130, maximum: 5),
        UpgradeDefinition(id: "alchemy", name: "調合の系譜", detail: "開始トニック+1。", baseCost: 145, maximum: 6)
    ]
}

struct ShopItem: Identifiable {
    let id: String
    let name: String
    let detail: String
    let price: Int
}

enum ShopCatalog {
    static let all = [
        ShopItem(id: "tonic", name: "旅人のトニック", detail: "次のサイクルのトニック+1", price: 70),
        ShopItem(id: "map", name: "裂け目の地図", detail: "次のサイクルの遺物候補+1", price: 160),
        ShopItem(id: "fortune", name: "黄金の糸", detail: "次のサイクルのゴールド+15%", price: 220),
        ShopItem(id: "ward", name: "守護の印", detail: "開始時の守り+20", price: 180),
        ShopItem(id: "echo", name: "輪廻の火種", detail: "残響+1", price: 900)
    ]
}

enum LogTone: String, Codable {
    case normal
    case good
    case danger
    case rare

    var color: Color {
        switch self {
        case .normal: return RiftboundTheme.muted
        case .good: return RiftboundTheme.mint
        case .danger: return RiftboundTheme.ember
        case .rare: return RiftboundTheme.gold
        }
    }
}

struct CombatLogEntry: Identifiable {
    let id = UUID()
    let text: String
    let tone: LogTone
}

struct SettingsState: Codable {
    var sound = true
    var vibration = true
    var reduceMotion = false
    var largeText = false
}

struct ProfileState: Codable {
    var gold = 140
    var fragments = 0
    var unlockedHeroes = ["wanderer"]
    var selectedHero = "wanderer"
    var buildByHero = ["wanderer": BuildType.balanced.rawValue]
    var upgrades = [String: Int]()
    var mastery = [String: Int](minimumCapacity: 10)
    var depth = 0
    var runs = 0
    var wins = 0
    var kills = 0
    var rooms = 0
    var rebirths = 0
    var weeklyWins = 0
    var endlessBest = 0
    var shopPotions = 0
    var shopGoldBonus = 0.0
    var shopDiscovery = 0
    var shopGuard = 0
    var defeatedEnemyIDs: [String] = []
    var achievementCount = 0
    var settings = SettingsState()
}

struct CycleSnapshot: Codable {
    var heroID: String
    var build: BuildType
    var mode: RunMode
    var depth: Int
    var roomNumber: Int
    var route: [RoomKind]
    var currentRoom: RoomKind
    var hp: Int
    var maxHP: Int
    var mp: Int
    var maxMP: Int
    var attack: Int
    var guardValue: Int
    var potions: Int
    var gold: Int
    var goldMultiplier: Double
    var enemy: Enemy?
    var eventText: String
    var eventChoices: [EventChoice]
    var rewardChoices: [Relic]
    var relics: [Relic]
    var showNextButton: Bool
    var rewardChosen: Bool
}
