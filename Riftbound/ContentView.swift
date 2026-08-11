import SwiftUI
import UIKit

struct ContentView: View {
    @EnvironmentObject private var game: GameStore

    var body: some View {
        ZStack {
            RiftboundBackground()
            Group {
                switch game.phase {
                case .title: TitleView()
                case .home: HomeView()
                case .running: RunView()
                case .victory: EndView(isVictory: true)
                case .defeated: EndView(isVictory: false)
                }
            }
            if let toast = game.toast {
                VStack {
                    Spacer()
                    Text(toast)
                        .font(.callout.weight(.semibold))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 11)
                        .background(RiftboundTheme.panelRaised, in: Capsule())
                        .overlay(Capsule().stroke(RiftboundTheme.mint.opacity(0.35), lineWidth: 1))
                        .padding(.bottom, 18)
                }
                .allowsHitTesting(false)
                .accessibilityElement(children: .combine)
                .accessibilityLabel(toast)
            }
        }
        .preferredColorScheme(.dark)
        .dynamicTypeSize(game.profile.settings.largeText ? .large : .medium)
    }
}

struct TitleView: View {
    @EnvironmentObject private var game: GameStore
    @State private var showHowToPlay = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    CapsuleLabel(text: "A POCKET ROGUELIKE RPG", color: RiftboundTheme.mint)
                    Spacer()
                    Text("v0.5.4")
                        .font(.caption.monospaced())
                        .foregroundStyle(RiftboundTheme.muted)
                }
                .padding(.top, 38)

                RiftSignalView(caption: "ARCHIVE 00 · LISTENING")
                    .padding(.top, 34)

                VStack(alignment: .leading, spacing: 0) {
                    Text("RIFT")
                    Text("BOUND")
                        .foregroundStyle(LinearGradient(colors: [RiftboundTheme.lilac, RiftboundTheme.blue], startPoint: .leading, endPoint: .trailing))
                }
                .font(.system(size: 64, weight: .black, design: .rounded))
                .tracking(-3)
                .padding(.top, 70)

                Text("降りるたび、新しい物語が始まる。\n勝利のたび、傷跡が残る。")
                    .font(.title3.weight(.medium))
                    .foregroundStyle(RiftboundTheme.text.opacity(0.82))
                    .lineSpacing(5)
                    .padding(.top, 22)

                VStack(spacing: 10) {
                    PrimaryWideButton(title: "裂け目へ向かう", icon: "arrow.up.right") {
                        game.enterHome()
                    }
                    SecondaryWideButton(title: "遊び方と長期進行", icon: "book.closed") {
                        showHowToPlay = true
                    }
                }
                .padding(.top, 42)

                if game.hasResume {
                    Button {
                        game.resumeRun()
                    } label: {
                        Label("前回のサイクルを再開", systemImage: "arrow.counterclockwise")
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .buttonStyle(.bordered)
                    .tint(RiftboundTheme.mint)
                    .padding(.top, 12)
                    .accessibilityHint("保存した部屋から続けます")
                }

                HStack(spacing: 8) {
                    Circle().fill(RiftboundTheme.ember).frame(width: 7, height: 7)
                    Text("THE VEIL IS HUNGRY TONIGHT")
                        .font(.caption2.weight(.bold).monospaced())
                        .tracking(1.2)
                        .foregroundStyle(RiftboundTheme.muted)
                }
                .padding(.top, 32)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 34)
        }
        .sheet(isPresented: $showHowToPlay) {
            HowToPlayView()
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
    }
}

struct HomeView: View {
    @EnvironmentObject private var game: GameStore

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("RIFTBOUND")
                            .font(.title2.weight(.black))
                        Text("裂け目の記録帳")
                            .font(.caption.monospaced())
                            .foregroundStyle(RiftboundTheme.muted)
                    }
                    Spacer()
                    Label("\(game.profile.gold)G", systemImage: "circle.fill")
                        .foregroundStyle(RiftboundTheme.gold)
                        .font(.headline.weight(.bold))
                }

                HStack(spacing: 8) {
                    HomeStat(value: "\(game.profile.runs)", label: "サイクル")
                    HomeStat(value: "\(game.profile.wins)", label: "勝利")
                    HomeStat(value: "\(game.profile.kills)", label: "討伐")
                    HomeStat(value: "\(game.profile.depth)", label: "深度")
                }

                RiftTelemetryCard(depth: game.profile.depth)

                PrimaryWideButton(title: "\(game.selectedHero.name)で出撃する", icon: "arrow.up.right") {
                    game.startNewRun()
                }

                if game.hasResume {
                    Button { game.resumeRun() } label: {
                        Label("前回のサイクルを再開", systemImage: "arrow.counterclockwise")
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .buttonStyle(.bordered)
                    .tint(RiftboundTheme.mint)
                }

                Text("旅人の記録")
                    .font(.title2.weight(.black))
                    .padding(.top, 8)
                Text("主人公、永続強化、召喚、挑戦、図鑑。毎サイクルの選択が次の旅を変える。")
                    .font(.subheadline)
                    .foregroundStyle(RiftboundTheme.muted)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 7) {
                        ForEach(HomeTab.allCases, id: \.self) { tab in
                            Button(tab.rawValue) { game.homeTab = tab }
                                .font(.caption.weight(.bold))
                                .foregroundStyle(game.homeTab == tab ? RiftboundTheme.text : RiftboundTheme.muted)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 9)
                                .background(game.homeTab == tab ? RiftboundTheme.panelRaised : RiftboundTheme.panel.opacity(0.72), in: RiftCutCornerShape(cut: 8))
                                .overlay(RiftCutCornerShape(cut: 8).stroke(game.homeTab == tab ? RiftboundTheme.cyan.opacity(0.42) : .white.opacity(0.06), lineWidth: 1))
                                .overlay(alignment: .bottom) {
                                    Rectangle()
                                        .fill(RiftboundTheme.mint)
                                        .frame(height: 2)
                                        .padding(.horizontal, 10)
                                        .opacity(game.homeTab == tab ? 1 : 0)
                                }
                        }
                    }
                }

                Group {
                    switch game.homeTab {
                    case .heroes: HeroRosterView()
                    case .tree: SkillTreeView()
                    case .shop: ShopView()
                    case .gacha: GachaView()
                    case .challenges: ChallengesView()
                    case .codex: CodexView()
                    case .settings: SettingsView()
                    }
                }
            }
            .padding(.horizontal, 18)
            .padding(.top, 20)
            .padding(.bottom, 30)
        }
    }
}

struct HeroRosterView: View {
    @EnvironmentObject private var game: GameStore

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionLabel(text: "HERO ROSTER · \(game.profile.unlockedHeroes.count)/\(Hero.catalog.count)")
            ForEach(Hero.catalog) { hero in
                HeroCard(hero: hero)
            }
            TipView(text: "通常攻撃はMP0。4系統ビルドと主人公習熟を組み合わせて高深度へ挑みます。")
        }
    }
}

struct HeroCard: View {
    @EnvironmentObject private var game: GameStore
    let hero: Hero

    private var unlocked: Bool { game.profile.unlockedHeroes.contains(hero.id) }
    private var selected: Bool { game.profile.selectedHero == hero.id }
    private var build: BuildType { BuildType(rawValue: game.profile.buildByHero[hero.id] ?? "") ?? .balanced }

    var body: some View {
        GlassPanel {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 12) {
                    Image(systemName: hero.icon)
                        .font(.system(size: 23, weight: .bold))
                        .frame(width: 48, height: 48)
                        .foregroundStyle(selected ? RiftboundTheme.mint : RiftboundTheme.lilac)
                        .background(RiftboundTheme.panelRaised, in: RiftCutCornerShape(cut: 8))
                        .overlay(RiftCutCornerShape(cut: 8).stroke(selected ? RiftboundTheme.mint.opacity(0.5) : .white.opacity(0.06), lineWidth: 1))
                    VStack(alignment: .leading, spacing: 3) {
                        HStack {
                            Text(hero.name).font(.headline.weight(.bold))
                            Text(hero.role).font(.caption2.weight(.bold)).foregroundStyle(RiftboundTheme.lilac)
                        }
                        Text(hero.description).font(.caption).foregroundStyle(RiftboundTheme.muted)
                    }
                    Spacer()
                    Button(unlocked ? (selected ? "選択中" : "選ぶ") : "\(hero.cost)G") { game.selectHero(hero) }
                        .font(.caption.weight(.bold))
                        .foregroundStyle(selected ? RiftboundTheme.mint : RiftboundTheme.gold)
                        .padding(.horizontal, 10)
                        .frame(minHeight: 32)
                        .background((selected ? RiftboundTheme.mint : RiftboundTheme.gold).opacity(0.12), in: RiftCutCornerShape(cut: 6))
                        .overlay(RiftCutCornerShape(cut: 6).stroke((selected ? RiftboundTheme.mint : RiftboundTheme.gold).opacity(0.42), lineWidth: 1))
                        .buttonStyle(.plain)
                        .disabled(!unlocked && game.profile.gold < hero.cost)
                }
                HStack(spacing: 12) {
                    StatPill(label: "HP", value: "\(hero.maxHP)")
                    StatPill(label: "MP", value: "\(hero.maxMP)")
                    StatPill(label: "ATK", value: "\(hero.attack)")
                    StatPill(label: "習熟", value: "\(game.profile.mastery[hero.id] ?? 0)")
                }
                if unlocked {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(BuildType.allCases, id: \.self) { option in
                                Button(option.title) { game.selectBuild(option, for: hero) }
                                    .font(.caption2.weight(.bold))
                                    .foregroundStyle(build == option ? RiftboundTheme.background : RiftboundTheme.muted)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 6)
                                    .background(build == option ? RiftboundTheme.mint.opacity(0.9) : RiftboundTheme.panelRaised, in: RiftCutCornerShape(cut: 5))
                                    .overlay(RiftCutCornerShape(cut: 5).stroke(build == option ? RiftboundTheme.mint : .white.opacity(0.08), lineWidth: 1))
                            }
                        }
                    }
                    Text("現在のビルド：\(build.title) · \(build.detail)")
                        .font(.caption2)
                        .foregroundStyle(RiftboundTheme.muted)
                }
                Text(hero.allSkills.map(\.name).joined(separator: " · "))
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(RiftboundTheme.lilac)
            }
        }
        .opacity(unlocked ? 1 : 0.68)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("\(hero.name)、\(hero.role)、HP\(hero.maxHP)、MP\(hero.maxMP)、攻撃\(hero.attack)")
    }
}

struct SkillTreeView: View {
    @EnvironmentObject private var game: GameStore

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionLabel(text: "永続スキルツリー · 次のサイクルへ")
            Text("現在のゴールド：\(game.profile.gold)G")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(RiftboundTheme.gold)
            ForEach(UpgradeCatalog.all) { definition in
                let level = game.upgradeLevel(definition.id)
                Button { game.buyUpgrade(definition) } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "arrow.up.circle.fill")
                            .foregroundStyle(RiftboundTheme.ember)
                        VStack(alignment: .leading, spacing: 3) {
                            Text(definition.name).font(.subheadline.weight(.bold))
                            Text(definition.detail).font(.caption).foregroundStyle(RiftboundTheme.muted)
                            Text(level >= definition.maximum ? "MAX" : "次の強化 \(game.upgradeCost(definition))G")
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(RiftboundTheme.gold)
                        }
                        Spacer()
                        Text("\(level)/\(definition.maximum)")
                            .font(.caption.monospaced().weight(.bold))
                            .foregroundStyle(RiftboundTheme.lilac)
                    }
                    .padding(13)
                    .background(RiftboundTheme.panelRaised, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .buttonStyle(.plain)
                .disabled(level >= definition.maximum)
            }
            TipView(text: "敗北しても持ち帰ったゴールドで強化できます。")
        }
    }
}

struct ShopView: View {
    @EnvironmentObject private var game: GameStore

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionLabel(text: "VEIL SHOP · 恒久準備")
            Text("次のサイクルへ持ち込む準備をゴールドで購入します。")
                .font(.caption)
                .foregroundStyle(RiftboundTheme.muted)
            ForEach(ShopCatalog.all) { item in
                Button { game.buyShopItem(item) } label: {
                    HStack {
                        Image(systemName: "circle.fill").foregroundStyle(RiftboundTheme.gold)
                        VStack(alignment: .leading, spacing: 3) {
                            Text(item.name).font(.subheadline.weight(.bold))
                            Text(item.detail).font(.caption).foregroundStyle(RiftboundTheme.muted)
                        }
                        Spacer()
                        Text("\(item.price)G").font(.caption.weight(.bold)).foregroundStyle(RiftboundTheme.gold)
                    }
                    .padding(13)
                    .background(RiftboundTheme.panelRaised, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
    }
}

struct GachaView: View {
    @EnvironmentObject private var game: GameStore

    var body: some View {
        GlassPanel {
            VStack(spacing: 13) {
                Image(systemName: "sparkles")
                    .font(.system(size: 38, weight: .bold))
                    .foregroundStyle(RiftboundTheme.lilac)
                Text("裂け目召喚").font(.title3.weight(.black))
                Text("ゲーム内ゴールドで主人公を迎え入れます。性能のある全主人公は直接解放もできます。")
                    .font(.caption)
                    .foregroundStyle(RiftboundTheme.muted)
                    .multilineTextAlignment(.center)
                Button {
                    game.summonHero()
                } label: {
                    Label("1回召喚する · 160G", systemImage: "sparkles")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(RiftboundTheme.lilac)
                Text("欠片 \(game.profile.fragments) · 5回ごとに未所持確定（Web版仕様）")
                    .font(.caption2)
                    .foregroundStyle(RiftboundTheme.muted)
            }
        }
    }
}

struct ChallengesView: View {
    @EnvironmentObject private var game: GameStore

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionLabel(text: "CHALLENGES · 長期プレイ")
            ChallengeButton(title: "デイリー裂け目", detail: "今日の深度規則と記録報酬", icon: "sun.max.fill", tint: RiftboundTheme.lilac) { game.startNewRun(.daily) }
            ChallengeButton(title: "ウィークリー契約", detail: "\(game.ruleText) · 週勝利 \(game.profile.weeklyWins)", icon: "calendar", tint: RiftboundTheme.blue) { game.startNewRun(.weekly) }
            ChallengeButton(title: "深層サイクル", detail: "4エリアを連結する26部屋", icon: "arrow.down.to.line", tint: RiftboundTheme.mint) { game.startNewRun(.deep) }
            ChallengeButton(title: "ボス連戦", detail: "3体のボスを6部屋で突破", icon: "crown.fill", tint: RiftboundTheme.crimson) { game.startNewRun(.bossRush) }
            ChallengeButton(title: "エンドレス", detail: "深度を更新し自己ベストを記録", icon: "infinity", tint: RiftboundTheme.gold) { game.startNewRun(.endless) }
        }
    }
}

struct CodexView: View {
    @EnvironmentObject private var game: GameStore

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionLabel(text: "ENEMY CODEX · \(game.profile.defeatedEnemyIDs.count)/\(Enemy.catalog.count)")
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 130), spacing: 8)], spacing: 8) {
                ForEach(Enemy.catalog) { enemy in
                    let seen = game.profile.defeatedEnemyIDs.contains(enemy.id)
                    VStack(alignment: .leading, spacing: 6) {
                        Image(systemName: enemySymbol(enemy))
                            .font(.system(size: 28, weight: .bold))
                            .frame(maxWidth: .infinity, minHeight: 56)
                            .foregroundStyle(seen ? RiftboundTheme.ember : RiftboundTheme.muted)
                        Text(seen ? enemy.name : "???").font(.caption.weight(.bold))
                        Text(seen ? enemy.intent : "討伐すると解放")
                            .font(.caption2)
                            .foregroundStyle(RiftboundTheme.muted)
                    }
                    .padding(10)
                    .background(RiftboundTheme.panelRaised, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
            }
            Text("遺物6種以上 · ボス9体 · 100実績カタログ · 外見30種")
                .font(.caption)
                .foregroundStyle(RiftboundTheme.muted)
        }
    }
}

struct SettingsView: View {
    @EnvironmentObject private var game: GameStore

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionLabel(text: "ACCESSIBILITY · 端末設定")
            GlassPanel {
                VStack(alignment: .leading, spacing: 13) {
                    SettingToggle(title: "効果音", detail: "攻撃・回復・報酬の効果音", value: Binding(get: { game.profile.settings.sound }, set: { game.setSetting(\SettingsState.sound, value: $0) }))
                    SettingToggle(title: "振動", detail: "入力と被弾を知らせる", value: Binding(get: { game.profile.settings.vibration }, set: { game.setSetting(\SettingsState.vibration, value: $0) }))
                    SettingToggle(title: "モーションを減らす", detail: "踏み込み・揺れを抑える", value: Binding(get: { game.profile.settings.reduceMotion }, set: { game.setSetting(\SettingsState.reduceMotion, value: $0) }))
                    SettingToggle(title: "大きな文字", detail: "ログと説明を読みやすくする", value: Binding(get: { game.profile.settings.largeText }, set: { game.setSetting(\SettingsState.largeText, value: $0) }))
                }
            }
            TipView(text: "色だけに頼らず、HP・MP・ラベル・アイコン・ログを同時に表示します。")
        }
    }
}

struct RunView: View {
    @EnvironmentObject private var game: GameStore

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 13) {
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(game.selectedHero.name).font(.title3.weight(.black))
                        Text("\(game.currentAreaName) · \(game.modeTitle) · 深度 \(game.depth) · \(game.selectedBuild.title)")
                            .font(.caption).foregroundStyle(RiftboundTheme.muted)
                    }
                    Spacer()
                    Text("● \(game.cycleGold)G").font(.headline.weight(.bold)).foregroundStyle(RiftboundTheme.gold)
                }
                RunCommandlineView()
                HStack(spacing: 8) {
                    Text("ROOM \(game.roomNumber) / \(game.route.count)")
                    Text(game.ruleText).lineLimit(1)
                }
                .font(.caption2.weight(.bold).monospaced())
                .foregroundStyle(RiftboundTheme.lilac)
                ProgressView(value: game.roomProgress).tint(RiftboundTheme.lilac)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 5) {
                        ForEach(Array(game.route.enumerated()), id: \.offset) { index, room in
                            Text(index + 1 == game.roomNumber ? room.icon : index < game.roomNumber ? "✓" : "·")
                                .font(.caption.weight(.bold))
                                .frame(width: 27, height: 27)
                                .foregroundStyle(index + 1 == game.roomNumber ? RiftboundTheme.text : index < game.roomNumber ? RiftboundTheme.mint : RiftboundTheme.muted)
                                .background(index + 1 == game.roomNumber ? RiftboundTheme.lilac.opacity(0.25) : RiftboundTheme.panelRaised, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                        }
                    }
                }

                RoomHeader(room: game.currentRoom)
                roomBody
                Button("ホームへ戻る") { game.abandonRun() }
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(RiftboundTheme.muted)
                    .accessibilityHint("現在のサイクルを中断し、ホームへ戻ります")
            }
            .padding(.horizontal, 18)
            .padding(.top, 16)
            .padding(.bottom, 30)
        }
    }

    @ViewBuilder
    private var roomBody: some View {
        switch game.currentRoom {
        case .battle, .elite, .boss:
            CombatRoomView()
        case .event:
            EventRoomView()
        case .rest:
            SimpleRoomView(icon: "flame.fill", title: "灯りの窪地", text: game.eventText, actionTitle: "灯りのそばで休む", isResolved: game.showNextButton, action: game.rest, nextAction: game.advanceFromRoom)
        case .treasure:
            SimpleRoomView(icon: "shippingbox.fill", title: "開かれた宝物庫", text: game.eventText, actionTitle: "宝物庫を開く", isResolved: game.showNextButton, action: game.openTreasure, nextAction: game.advanceFromRoom)
        }
    }
}

struct CombatRoomView: View {
    @EnvironmentObject private var game: GameStore

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let enemy = game.currentEnemy {
                GlassPanel {
                    HStack(alignment: .bottom, spacing: 8) {
                        FighterPanel(name: game.selectedHero.name, icon: game.selectedHero.icon, artName: game.selectedHero.artName, hp: game.hp, maxHP: game.maxHP, mp: game.mp, maxMP: game.maxMP, tint: RiftboundTheme.mint, animation: game.combatAnimation, isEnemy: false, reduceMotion: game.profile.settings.reduceMotion)
                        Text("VS").font(.caption.weight(.black)).foregroundStyle(RiftboundTheme.gold)
                        FighterPanel(name: enemy.name, icon: enemySymbol(enemy), artName: enemy.imageName, hp: enemy.hp, maxHP: enemy.maxHP, mp: 0, maxMP: 1, tint: RiftboundTheme.crimson, animation: game.combatAnimation, isEnemy: true, reduceMotion: game.profile.settings.reduceMotion)
                    }
                    .accessibilityElement(children: .contain)
                    .accessibilityLabel("\(game.selectedHero.name) HP\(game.hp) MP\(game.mp)、敵\(enemy.name) HP\(enemy.hp)")
                }
                Text("予告 · \(enemy.intent)")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(RiftboundTheme.crimson)
                if game.showNextButton {
                    RewardView()
                } else {
                    VStack(spacing: 8) {
                        ActionButton(title: "通常攻撃", subtitle: "MPを消費しない基本攻撃 · MP 0", icon: "slash.circle.fill", tint: RiftboundTheme.mint, isPrimary: true, action: game.normalAttack)
                            .disabled(game.currentEnemy == nil || game.isAnimating)
                        ForEach(game.currentSkills) { skill in
                            SkillActionView(skill: skill)
                        }
                        HStack(spacing: 8) {
                            ActionButton(title: "守る", subtitle: "守り+18", icon: "shield.fill", tint: RiftboundTheme.blue, isPrimary: false, action: game.guardAction)
                                .disabled(game.isAnimating)
                            ActionButton(title: "トニック", subtitle: "HP回復 · ×\(game.potions)", icon: "drop.fill", tint: RiftboundTheme.gold, isPrimary: false, action: game.drinkPotion)
                                .disabled(game.isAnimating || game.potions == 0 || game.hp >= game.maxHP)
                        }
                    }
                }
            }
            LogView(entries: game.log)
        }
    }
}

struct SkillActionView: View {
    @EnvironmentObject private var game: GameStore
    let skill: HeroSkill

    var body: some View {
        ActionButton(title: skill.name, subtitle: "\(skill.detail) · MP \(skill.cost)", icon: skill.icon, tint: RiftboundTheme.lilac, isPrimary: false) {
            game.useSkill(skill)
        }
        .disabled(game.isAnimating || game.mp < skill.cost)
        .accessibilityLabel("\(skill.name)、MP\(skill.cost)、\(skill.detail)")
    }
}

struct RewardView: View {
    @EnvironmentObject private var game: GameStore

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            if !game.rewardChosen {
                Text("遺物を1つ選ぶ").font(.headline.weight(.bold))
                ForEach(game.rewardChoices) { relic in
                    Button { game.chooseRelic(relic) } label: {
                        HStack {
                            Image(systemName: "diamond.fill").foregroundStyle(RiftboundTheme.gold)
                            VStack(alignment: .leading, spacing: 3) {
                                Text(relic.name).font(.subheadline.weight(.bold))
                                Text(relic.detail).font(.caption).foregroundStyle(RiftboundTheme.muted)
                            }
                            Spacer()
                            Text(relic.tag).font(.caption2.weight(.bold)).foregroundStyle(RiftboundTheme.lilac)
                        }
                        .padding(12)
                        .background(RiftboundTheme.panelRaised, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            } else {
                Text(game.rewardText).font(.subheadline.weight(.bold)).foregroundStyle(RiftboundTheme.gold)
                Button("次の部屋へ") { game.advanceFromRoom() }
                    .buttonStyle(.borderedProminent)
                    .tint(RiftboundTheme.lilac)
            }
        }
    }
}

struct EventRoomView: View {
    @EnvironmentObject private var game: GameStore

    var body: some View {
        GlassPanel {
            VStack(alignment: .leading, spacing: 12) {
                Text(game.eventText).font(.body).lineSpacing(4)
                if game.showNextButton {
                    Text("選択の結果を背負い、先へ進める。")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(RiftboundTheme.mint)
                    Button("歩みを進める") { game.advanceFromRoom() }
                        .buttonStyle(.borderedProminent)
                        .tint(RiftboundTheme.lilac)
                } else {
                    ForEach(game.eventChoices) { choice in
                        Button { game.chooseEvent(choice) } label: {
                            HStack {
                                Image(systemName: choice.icon).foregroundStyle(RiftboundTheme.lilac)
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(choice.title).font(.subheadline.weight(.bold))
                                    Text(choice.detail).font(.caption).foregroundStyle(RiftboundTheme.muted)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                            }
                            .padding(12)
                            .background(RiftboundTheme.panelRaised, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
}

struct SimpleRoomView: View {
    let icon: String
    let title: String
    let text: String
    let actionTitle: String
    let isResolved: Bool
    let action: () -> Void
    let nextAction: () -> Void

    var body: some View {
        GlassPanel {
            VStack(alignment: .leading, spacing: 12) {
                Label(title, systemImage: icon).font(.headline.weight(.bold))
                Text(text).font(.body).foregroundStyle(RiftboundTheme.muted)
                if isResolved {
                    Button("次の部屋へ", action: nextAction)
                        .buttonStyle(.borderedProminent)
                        .tint(RiftboundTheme.mint)
                } else {
                    Button(actionTitle, action: action)
                        .buttonStyle(.borderedProminent)
                        .tint(RiftboundTheme.gold)
                }
            }
        }
    }
}

struct EndView: View {
    @EnvironmentObject private var game: GameStore
    let isVictory: Bool

    var body: some View {
        VStack(spacing: 18) {
            Image(systemName: isVictory ? "crown.fill" : "moon.fill")
                .font(.system(size: 50, weight: .bold))
                .foregroundStyle(isVictory ? RiftboundTheme.gold : RiftboundTheme.crimson)
            Text(isVictory ? "裂け目が、あなたを覚えた" : "今回は、ここまで")
                .font(.title.weight(.black))
                .multilineTextAlignment(.center)
            Text(isVictory ? "確保したゴールドと習熟は次のサイクルへ持ち越されます。" : "敗北しても、サイクル中のゴールドと習熟は失われません。")
                .font(.body)
                .foregroundStyle(RiftboundTheme.muted)
                .multilineTextAlignment(.center)
            HStack(spacing: 18) {
                EndStat(label: "G", value: "\(game.profile.gold)")
                EndStat(label: "深度", value: "\(game.profile.depth)")
                EndStat(label: "勝利", value: "\(game.profile.wins)")
            }
            PrimaryWideButton(title: "もう一度進む", icon: "arrow.up.right") { game.startNewRun() }
            SecondaryWideButton(title: "記録帳へ戻る", icon: "house.fill") { game.enterHome() }
        }
        .padding(.horizontal, 24)
    }
}

struct RoomHeader: View {
    let room: RoomKind

    var body: some View {
        GlassPanel {
            HStack(spacing: 12) {
                Image(systemName: room.icon)
                    .font(.title3.weight(.bold))
                    .frame(width: 42, height: 42)
                    .foregroundStyle(room.tint)
                    .background(room.tint.opacity(0.14), in: RoundedRectangle(cornerRadius: 13, style: .continuous))
                VStack(alignment: .leading, spacing: 4) {
                    Text(room.badge).font(.caption2.weight(.bold).monospaced()).foregroundStyle(room.tint)
                    Text(room.title).font(.headline.weight(.bold))
                    Text(room.subtitle).font(.caption).foregroundStyle(RiftboundTheme.muted)
                }
            }
        }
    }
}

struct FighterPanel: View {
    let name: String
    let icon: String
    let artName: String?
    let hp: Int
    let maxHP: Int
    let mp: Int
    let maxMP: Int
    let tint: Color
    let animation: CombatAnimation
    let isEnemy: Bool
    let reduceMotion: Bool

    private var horizontalOffset: CGFloat {
        switch animation {
        case .playerAttack:
            return isEnemy ? 4 : 18
        case .enemyAttack:
            return isEnemy ? -18 : -4
        case .skill:
            return isEnemy ? 5 : 13
        default:
            return 0
        }
    }

    private var verticalOffset: CGFloat {
        animation == .heal && !isEnemy ? -8 : 0
    }

    private var imageScale: CGFloat {
        animation == .skill && !isEnemy ? 1.08 : animation == .heal && !isEnemy ? 1.05 : 1
    }

    var body: some View {
        VStack(spacing: 7) {
            Group {
                if let artName, let image = UIImage(named: artName) {
                    Image(uiImage: image)
                        .resizable()
                        .interpolation(.none)
                        .scaledToFit()
                } else {
                    Image(systemName: icon)
                        .font(.system(size: 38, weight: .bold))
                }
            }
                .frame(height: 92)
                .scaleEffect(x: isEnemy ? 1 : 1, y: 1)
                .offset(x: reduceMotion ? 0 : horizontalOffset, y: reduceMotion ? 0 : verticalOffset)
                .scaleEffect(reduceMotion ? 1 : imageScale)
                .overlay {
                    if animation == .enemyAttack && !isEnemy {
                        Circle().fill(RiftboundTheme.crimson.opacity(0.24)).blur(radius: 12)
                    } else if animation == .skill && !isEnemy {
                        Circle().fill(RiftboundTheme.lilac.opacity(0.26)).blur(radius: 14)
                    } else if animation == .heal && !isEnemy {
                        Circle().fill(RiftboundTheme.mint.opacity(0.22)).blur(radius: 14)
                    }
                }
                .animation(reduceMotion ? nil : .easeOut(duration: 0.38), value: animation)
                .accessibilityLabel("\(name)のドット絵")
            Text(name).font(.caption.weight(.bold)).lineLimit(1)
            StatBar(value: hp, maxValue: maxHP, color: tint, icon: "heart.fill", label: "HP")
            if maxMP > 1 {
                StatBar(value: mp, maxValue: maxMP, color: RiftboundTheme.lilac, icon: "bolt.fill", label: "MP")
            }
        }
        .frame(maxWidth: .infinity)
    }
}

struct LogView: View {
    let entries: [CombatLogEntry]

    var body: some View {
        if !entries.isEmpty {
            VStack(alignment: .leading, spacing: 6) {
                Text("RUN LOG").font(.caption2.weight(.bold).monospaced()).foregroundStyle(RiftboundTheme.muted)
                ForEach(entries) { entry in
                    HStack(alignment: .top, spacing: 6) {
                        Circle().fill(entry.tone.color).frame(width: 5, height: 5).padding(.top, 5)
                        Text(entry.text).font(.caption).foregroundStyle(entry.tone.color)
                    }
                }
            }
            .padding(.top, 4)
            .accessibilityElement(children: .combine)
        }
    }
}

struct HowToPlayView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text("遊び方と長期進行").font(.title2.weight(.black))
                Text("通常攻撃はMP0。MPを使う固有スキル、守り、トニックを組み合わせて敵の予告をしのぎます。")
                Text("敵を倒すと遺物を1つ選べます。選んだ遺物と主人公の能力で、毎サイクルのビルドが変化します。")
                Text("勝利でも敗北でも、サイクル中のゴールドと主人公習熟を保存します。")
                Text("通常エンディングの先には、深度、実績、図鑑、主人公習熟、召喚の収集が待っています。")
            }
            .font(.body)
            .foregroundStyle(RiftboundTheme.text.opacity(0.86))
            .lineSpacing(4)
            .padding(22)
        }
        .background(RiftboundTheme.background)
    }
}

struct HomeStat: View {
    let value: String
    let label: String

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(value).font(.title3.weight(.black))
            Text(label).font(.caption2.weight(.bold).monospaced()).foregroundStyle(RiftboundTheme.muted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(RiftboundTheme.panel, in: RoundedRectangle(cornerRadius: 13, style: .continuous))
    }
}

struct StatPill: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label).font(.caption2.monospaced()).foregroundStyle(RiftboundTheme.muted)
            Text(value).font(.caption.weight(.bold))
        }
    }
}

struct SectionLabel: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.caption2.weight(.bold).monospaced())
            .tracking(1.2)
            .foregroundStyle(RiftboundTheme.muted)
    }
}

struct TipView: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.caption)
            .foregroundStyle(RiftboundTheme.text.opacity(0.78))
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RiftboundTheme.lilac.opacity(0.08), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

struct ChallengeButton: View {
    let title: String
    let detail: String
    let icon: String
    let tint: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon).foregroundStyle(tint).frame(width: 28)
                VStack(alignment: .leading, spacing: 3) {
                    Text(title).font(.subheadline.weight(.bold))
                    Text(detail).font(.caption).foregroundStyle(RiftboundTheme.muted)
                }
                Spacer()
                Image(systemName: "chevron.right").foregroundStyle(tint)
            }
            .padding(13)
            .background(RiftboundTheme.panelRaised, in: RiftCutCornerShape(cut: 10))
            .overlay(RiftCutCornerShape(cut: 10).stroke(.white.opacity(0.06), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}

struct SettingToggle: View {
    let title: String
    let detail: String
    @Binding var value: Bool

    var body: some View {
        Toggle(isOn: $value) {
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.subheadline.weight(.bold))
                Text(detail).font(.caption).foregroundStyle(RiftboundTheme.muted)
            }
        }
        .tint(RiftboundTheme.mint)
    }
}

struct EndStat: View {
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: 3) {
            Text(value).font(.title2.weight(.black))
            Text(label).font(.caption2.weight(.bold).monospaced()).foregroundStyle(RiftboundTheme.muted)
        }
    }
}

struct PrimaryWideButton: View {
    let title: String
    let icon: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Text(title)
                Spacer()
                Image(systemName: icon)
            }
            .font(.headline.weight(.bold))
            .foregroundStyle(RiftboundTheme.background)
            .padding(.horizontal, 17)
            .frame(height: 58)
            .background(
                LinearGradient(colors: [RiftboundTheme.text, RiftboundTheme.mint.opacity(0.85)], startPoint: .leading, endPoint: .trailing),
                in: RiftCutCornerShape(cut: 10)
            )
            .overlay(RiftCutCornerShape(cut: 10).stroke(RiftboundTheme.mint.opacity(0.35), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}

struct SecondaryWideButton: View {
    let title: String
    let icon: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                Text(title)
                Spacer()
                Image(systemName: "chevron.right")
            }
            .font(.subheadline.weight(.bold))
            .foregroundStyle(RiftboundTheme.text)
            .padding(.horizontal, 17)
            .frame(height: 52)
            .background(RiftboundTheme.panel.opacity(0.92), in: RiftCutCornerShape(cut: 9))
            .overlay(RiftCutCornerShape(cut: 9).stroke(RiftboundTheme.lilac.opacity(0.25), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}

private func enemySymbol(_ enemy: Enemy) -> String {
    if enemy.id.contains("dragon") { return "diamond.fill" }
    if enemy.isBoss { return "crown.fill" }
    if enemy.imageName.contains("wisp") { return "sparkles" }
    if enemy.imageName.contains("hound") { return "pawprint.fill" }
    if enemy.imageName.contains("glass") || enemy.imageName.contains("mantis") { return "circle.hexagongrid.fill" }
    return "flame.fill"
}

#Preview("Home") {
    ContentView()
        .environmentObject(GameStore())
}
