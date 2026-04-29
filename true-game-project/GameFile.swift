import SwiftUI
import AVFoundation
// ─────────────────────────────────────────────────────────────────
// DESIGN CANVAS — the coordinate space the game was authored in.
// ALL @State positions and rects live in this space forever.
// Only the VIEW layer multiplies by S when placing/sizing things.
//
// The actual game content spans x: 550–1440 (890 pts wide) and
// y: 100–1000 (900 pts tall).  Setting the canvas to 1440×1000
// means S = min(1366/1440, 1024/1000) ≈ 0.949 on iPad Pro 13"
// landscape — fills almost the full screen with no clipping.
// ─────────────────────────────────────────────────────────────────
private let designWidth:  CGFloat = 1440
private let designHeight: CGFloat = 950

private let globalScreenOffset = CGSize(width: -55, height: -25)

@MainActor
struct ContentView: View {

    // ── Scale — computed once from GeometryReader ─────────────────
    @State private var S: CGFloat = 1.0

    // ── Player (design-space) ─────────────────────────────────────
    @State private var playerPosition  = CGPoint(x: 700, y: 500)
    @State private var dragOffset      = CGSize.zero
    @State private var attackOffset    = CGSize.zero
    @State private var joystickVector  = CGVector.zero
    @State private var coolDown        = false
    @State private var attackButtonPressed = false
    @State private var MothSprite      = "Moth"
    @State private var showDebug       = false
    @State private var MothHP          = 50.0
    @State private var joystickbOp     = 0.3
    @State private var JoystickOp      = 0.8
    @State private var ATTACKOP        = 1.0
    @State private var attackAnimationVisible = false
    @State private var attackFrame     = 0
    @State private var hitboxVisible   = 0.0
    @State private var hitboxPosition1 = CGPoint(x: 200, y: 300)   // design-space

    // ── Boss (design-space) ───────────────────────────────────────
    @State private var bossSprite      = "Boss Frame One"
    @State private var BossPos         = CGPoint(x: 1000, y: 151)  // design-space
    @State private var bossAttack      = "Boss attack 0"
    @State private var bossAttack2     = "Boss attack 0"
    @State private var bossAttack3     = "Boss attack 0"
    @State private var bossAttack4     = "Boss attack 0"
    @State private var bossAttack5     = "Boss attack 0"
    @State private var bossAttack6     = "Boss attack 0"
    @State private var bossAttackSpriteRandom  = Int.random(in: 1...3)
    @State private var bossAttackSpriteRandom2 = Int.random(in: 1...3)
    @State private var bossAttackSpriteRandom3 = Int.random(in: 1...3)
    @State private var bossAttackSpriteRandom4 = Int.random(in: 1...3)
    @State private var bossAttackSpriteRandom5 = Int.random(in: 1...3)
    @State private var bossAttackSpriteRandom6 = Int.random(in: 1...3)
    @State private var BossHP          = "HP5"
    @State private var BossHPValue     = 5
    @State private var lastBossHitTime: TimeInterval = 0

    // ── Boss attack spawn positions (design-space) ────────────────
    @State private var randomNumberx  = Double.random(in: 550...1390)
    @State private var randomNumber2x = Double.random(in: 550...1390)
    @State private var randomNumber3x = Double.random(in: 550...1390)
    @State private var randomNumber4x = Double.random(in: 550...1390)
    @State private var randomNumber5x = Double.random(in: 550...1390)
    @State private var randomNumber6x = Double.random(in: 550...1390)
    @State private var randomNumbery  = Double.random(in: 330...850)
    @State private var randomNumber2y = Double.random(in: 330...850)
    @State private var randomNumber3y = Double.random(in: 330...850)
    @State private var randomNumber4y = Double.random(in: 330...850)
    @State private var randomNumber5y = Double.random(in: 330...850)
    @State private var randomNumber6y = Double.random(in: 330...850)

    // ── Protec / shield (design-space) ────────────────────────────
    @State private var ProtecY   = Double.random(in: 430...750)
    @State private var ProtecX   = Double.random(in: 650...1390)
    @State private var Protec    = false
    @State private var mothInPro = false

    // ── Timers ────────────────────────────────────────────────────
    @State private var isMoving               = false
    @State private var movementLoopTimer:      Timer?
    @State private var gameTimer:              Timer?
    @State private var bossMovTimer:           Timer?
    @State private var bossSpriteTimer:        Timer?
    @State private var bossAttackTimer:        Timer?
    @State private var bossAttackSwitchTimer:  Timer?
    @State private var bossAttackSwitchTimer2: Timer?
    @State private var batterySwitchTimer:     Timer?
    @State private var BigAttackTimer:         Timer?
    @State private var BigAttackShieldTimer:   Timer?
    @State private var BigAttackEndTimer:      Timer?

    // ── Batteries ────────────────────────────────────────────────
    @State private var Battery  = "BatteryBoss"
    @State private var Battery2 = "BatteryBoss"
    @State private var Battery3 = "BatteryBoss"
    @State private var Battery4 = "BatteryBoss"
    @State private var Battery5 = "BatteryBoss"
    @State private var activeBattery     = Int.random(in: 1...5)
    @State private var aBattery1         = 1.0
    @State private var aBattery2         = 1.0
    @State private var aBattery3         = 1.0
    @State private var aBattery4         = 1.0
    @State private var aBattery5         = 1.0
    @State private var BatterHP          = 200.0
    @State private var BatterHP2         = 200.0
    @State private var BatterHP3         = 200.0
    @State private var BatterHP4         = 200.0
    @State private var BatterHP5         = 200.0
    @State private var batteryBehindOpacity: Double = 1.0
    @State private var hitBattery1 = false
    @State private var hitBattery2 = false
    @State private var hitBattery3 = false
    @State private var hitBattery4 = false
    @State private var hitBattery5 = false
    @State private var MothBattery1 = ""
    @State private var MothBattery2 = ""
    @State private var MothBattery3 = ""
    @State private var MothBattery4 = ""
    @State private var MothBattery5 = ""

    // ── Phase 2 / big attack ─────────────────────────────────────
    @State private var phase2         = false
    @State private var Bigtack        = false
    @State private var biggattackTime = Double.random(in: 10...40)
    @State private var LightningAttak1  = "LightningBeam1"
    @State private var LightningAttak2  = "LightningBeam1"
    @State private var LightningAttak3  = "LightningBeam1"
    @State private var LightningAttak4  = "LightningBeam1"
    @State private var LightningAttak5  = "LightningBeam1"
    @State private var LightningAttak6  = "LightningBeam1"
    @State private var LightningAttak7  = "LightningBeam1"
    @State private var LightningAttak8  = "LightningBeam1"
    @State private var LightningAttak9  = "LightningBeam1"
    @State private var LightningAttak10 = "LightningBeam1"
    @State private var LightningAttak11 = "LightningBeam1"
    @State private var LightningAttak12 = "LightningBeam1"
    @State private var LightningAttak13 = "LightningBeam1"
    @State private var LightningAttak14 = "LightningBeam1"
    @State private var LightningAttak15 = "LightningBeam1"
    @State private var LightningAttak16 = "LightningBeam1"
    @State private var LightningAttak17 = "LightningBeam1"
    @State private var bossBigLightSpriteRandom1  = Int.random(in: 1...4)
    @State private var bossBigLightSpriteRandom2  = Int.random(in: 1...4)
    @State private var bossBigLightSpriteRandom3  = Int.random(in: 1...4)
    @State private var bossBigLightSpriteRandom4  = Int.random(in: 1...4)
    @State private var bossBigLightSpriteRandom5  = Int.random(in: 1...4)
    @State private var bossBigLightSpriteRandom6  = Int.random(in: 1...4)
    @State private var bossBigLightSpriteRandom7  = Int.random(in: 1...4)
    @State private var bossBigLightSpriteRandom8  = Int.random(in: 1...4)
    @State private var bossBigLightSpriteRandom9  = Int.random(in: 1...4)
    @State private var bossBigLightSpriteRandom10 = Int.random(in: 1...4)
    @State private var bossBigLightSpriteRandom11 = Int.random(in: 1...4)
    @State private var bossBigLightSpriteRandom12 = Int.random(in: 1...4)
    @State private var bossBigLightSpriteRandom13 = Int.random(in: 1...4)
    @State private var bossBigLightSpriteRandom14 = Int.random(in: 1...4)
    @State private var bossBigLightSpriteRandom15 = Int.random(in: 1...4)
    @State private var bossBigLightSpriteRandom16 = Int.random(in: 1...4)
    @State private var bossBigLightSpriteRandom17 = Int.random(in: 1...4)

    // ── Misc ─────────────────────────────────────────────────────
    @State private var reset         = false
    @State private var deadscrean    = 0.0
    @State private var lastDirection = "down"
    @State private var animationFrame = 0
    @State private var moveSpeed: CGFloat = 3.0
    @State private var attackswithtrue = true
    @State private var lastWallDamageTime: TimeInterval = 0

    // ─────────────────────────────────────────────────────────────
    // CONSTANTS — all in design-space
    // Controls bumped ~30% larger for better touch targets at 0.68x
    // ─────────────────────────────────────────────────────────────
    let joystickSize:  CGFloat = 169
    let knobSize:      CGFloat = 67.6
    let joystickSize2: CGFloat = 320
    let knobSize2:     CGFloat = 80
    let wallDamageAmount:  Double        = 0.2
    let wallDamageCooldown: TimeInterval = 0.005
    let playerSize:   CGFloat = 50
    let playerRadius: CGFloat = 18
    let attackSize:   CGFloat = 50
    let bossAttackRadius:  CGFloat        = 50
    let bossAttackYOffset: CGFloat        = 120
    var bossAttackDamage:  Double         = 0.07
    let bossAttackCooldown: TimeInterval  = 0

    // Wall rects — design-space
    let wallRects: [CGRect] = [
        CGRect(x: 600,  y: 330, width: 1000, height: 50),
        CGRect(x: 1390, y: 100, width: 50,   height: 900),
        CGRect(x: 550,  y: 100, width: 50,   height: 900),
        CGRect(x: 600,  y: 850, width: 1000, height: 50)
    ]
    // Battery hitboxes — design-space
    let batterBox:  [CGRect] = [CGRect(x: 1250, y: 150, width: 110, height: 235)]
    let batterBox2: [CGRect] = [CGRect(x: 650,  y: 350, width: 110, height: 235)]
    let batterBox3: [CGRect] = [CGRect(x: 1150, y: 450, width: 110, height: 235)]
    let batterBox4: [CGRect] = [CGRect(x: 850,  y: 650, width: 110, height: 235)]
    let batterBox5: [CGRect] = [CGRect(x: 950,  y: 400, width: 110, height: 235)]

    // ─────────────────────────────────────────────────────────────
    // VIEW HELPERS
    // Rule: ALL @State positions are design-space.
    // Only multiply by S here in the view layer — never in logic.
    // ─────────────────────────────────────────────────────────────

    // Scale a design-space CGPoint → screen-space for .position()
    func vp(_ p: CGPoint) -> CGPoint {
        CGPoint(x: p.x * S + globalScreenOffset.width, y: p.y * S + globalScreenOffset.height)
    }

    // Scale a single design-space CGFloat value
    func vs(_ v: CGFloat) -> CGFloat { v * S }

    // Scale a design-space CGRect → screen-space (for collision)
    func vr(_ r: CGRect) -> CGRect {
        CGRect(x: r.origin.x * S + globalScreenOffset.width,
               y: r.origin.y * S + globalScreenOffset.height,
               width: r.width * S, height: r.height * S)
    }

    // Screen-space collision rects (computed lazily each frame)
    var scaledWalls: [CGRect] { wallRects.map  { vr($0) } }
    var scaledBBox1: [CGRect] { batterBox.map  { vr($0) } }
    var scaledBBox2: [CGRect] { batterBox2.map { vr($0) } }
    var scaledBBox3: [CGRect] { batterBox3.map { vr($0) } }
    var scaledBBox4: [CGRect] { batterBox4.map { vr($0) } }
    var scaledBBox5: [CGRect] { batterBox5.map { vr($0) } }

    // ─────────────────────────────────────────────────────────────
    // BODY
    // ─────────────────────────────────────────────────────────────
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .topLeading) {
                Color.black.ignoresSafeArea()

                // ── Backdrop ─────────────────────────────────
                Image("BackDrop2")
                    .resizable()
                    .interpolation(.none)
                    .frame(width: vs(3000), height: vs(1000))
                    .position(x: vs(1000) + globalScreenOffset.width,
                              y: vs(500)  + globalScreenOffset.height)

                // ── Protec shield ─────────────────────────────
                if Protec && BossHPValue <= 3 {
                    Image("Protec")
                        .resizable()
                        .interpolation(.none)
                        .frame(width: vs(150), height: vs(150))
                        .position(x: CGFloat(ProtecX) * S + globalScreenOffset.width,
                                  y: CGFloat(ProtecY) * S + globalScreenOffset.height)
                    if showDebug {
                        let pBox = CGRect(x: (ProtecX - 75) * S + globalScreenOffset.width,
                                         y: (ProtecY - 75) * S + globalScreenOffset.height,
                                         width: vs(150), height: vs(150))
                        Rectangle()
                            .stroke(Color.purple, lineWidth: 2)
                            .frame(width: pBox.width, height: pBox.height)
                            .position(x: pBox.midX, y: pBox.midY)
                    }
                }

                // ── Walls overlay image ───────────────────────
                Image("walls")
                    .resizable()
                    .interpolation(.none)
                    .frame(width: vs(3000), height: vs(1000))
                    .position(x: vs(1000) + globalScreenOffset.width,
                              y: vs(500)  + globalScreenOffset.height)

                // ── Boss attack hit circles (faint) ──────────
                ForEach(0..<6, id: \.self) { i in
                    let (ax, ay) = bossAttackDesignPos(i)
                    Circle()
                        .foregroundColor(.cyan)
                        .frame(width: vs(bossAttackRadius) * 2,
                               height: vs(bossAttackRadius) * 2)
                        .opacity(0.1)
                        .position(x: CGFloat(ax) * S + globalScreenOffset.width,
                                  y: (CGFloat(ay) + bossAttackYOffset) * S + globalScreenOffset.height)
                }

                // ── Moth (player) sprite ──────────────────────
                // playerPosition stays in design-space; vp() converts for .position()
                Image(MothSprite)
                    .resizable()
                    .interpolation(.none)
                    .frame(width: vs(playerSize), height: vs(playerSize))
                    .position(vp(playerPosition))

                // ── Boss sprite ───────────────────────────────
                // BossPos stays in design-space; vp() converts for .position()
                Image(bossSprite)
                    .resizable()
                    .interpolation(.none)
                    .frame(width: vs(300), height: vs(300))
                    .position(vp(BossPos))

                // ── Player HP bar ─────────────────────────────
                Rectangle()
                    .foregroundColor(.black)
                    .frame(width: vs(55), height: vs(15))
                    .position(vp(playerPosition))
                    .offset(CGSize(width: 0, height: -vs(30)))
                Rectangle()
                    .foregroundColor(.purple)
                    .frame(width: CGFloat(MothHP) * S, height: vs(10))
                    .position(vp(playerPosition))
                    .offset(CGSize(width: 0, height: -vs(30)))

                // ── Lightning / big attack ────────────────────
                if Bigtack && BossHPValue <= 3 {
                    let lightningX: [CGFloat] = [
                        600, 650, 700, 750, 800, 850, 900, 950,
                        1000, 1050, 1100, 1150, 1200, 1250, 1300, 1350, 1400
                    ]
                    let lightningSprites = [
                        LightningAttak1,  LightningAttak2,  LightningAttak3,
                        LightningAttak4,  LightningAttak5,  LightningAttak6,
                        LightningAttak7,  LightningAttak8,  LightningAttak9,
                        LightningAttak10, LightningAttak11, LightningAttak12,
                        LightningAttak13, LightningAttak14, LightningAttak15,
                        LightningAttak16, LightningAttak17
                    ]
                    ForEach(lightningSprites.indices, id: \.self) { i in
                        Image(lightningSprites[i])
                            .resizable()
                            .interpolation(.none)
                            .frame(width: vs(100), height: vs(500))
                            .position(x: lightningX[i] * S + globalScreenOffset.width,
                                      y: vs(600) + globalScreenOffset.height)
                    }
                }

                // ── Boss attack sprites ───────────────────────
                let bossAttacks = [bossAttack, bossAttack2, bossAttack3,
                                   bossAttack4, bossAttack5, bossAttack6]
                ForEach(bossAttacks.indices, id: \.self) { i in
                    let (ax, ay) = bossAttackDesignPos(i)
                    Image(bossAttacks[i])
                        .resizable()
                        .interpolation(.none)
                        .frame(width: vs(150), height: vs(300))
                        .position(x: CGFloat(ax) * S + globalScreenOffset.width,
                                  y: CGFloat(ay) * S + globalScreenOffset.height)
                }

                // ── Batteries ─────────────────────────────────
                batteryView(sprite: Battery,  x: 1300, y: 200,
                            opacity: activeBattery == 1 ? batteryBehindOpacity : aBattery1)
                batteryView(sprite: Battery2, x: 700,  y: 400,
                            opacity: activeBattery == 2 ? batteryBehindOpacity : aBattery2)
                batteryView(sprite: Battery3, x: 1200, y: 500,
                            opacity: activeBattery == 3 ? batteryBehindOpacity : aBattery3)
                batteryView(sprite: Battery4, x: 900,  y: 700,
                            opacity: activeBattery == 4 ? batteryBehindOpacity : aBattery4)
                batteryView(sprite: Battery5, x: 1000, y: 450,
                            opacity: activeBattery == 5 ? batteryBehindOpacity : aBattery5)

                // ── Moth batteries (collected) ─────────────────
                mothBatteryView(sprite: MothBattery1, y: 200)
                mothBatteryView(sprite: MothBattery2, y: 300)
                mothBatteryView(sprite: MothBattery3, y: 400)
                mothBatteryView(sprite: MothBattery4, y: 500)
                mothBatteryView(sprite: MothBattery5, y: 600)

                // ── Crosshair ─────────────────────────────────
                Image("Cross-Hair")
                    .resizable()
                    .interpolation(.none)
                    .opacity(hitboxVisible)
                    .frame(width: vs(attackSize), height: vs(attackSize))
                    .position(vp(hitboxPosition1))

                // ── Battery HP bars ───────────────────────────
                if hitBattery1 {
                    batteryHPBar(x: 1300, y: 200, hp: BatterHP,
                                 op: activeBattery == 1 ? batteryBehindOpacity : aBattery1)
                }
                if hitBattery2 {
                    batteryHPBar(x: 700,  y: 400, hp: BatterHP2,
                                 op: activeBattery == 2 ? batteryBehindOpacity : aBattery2)
                }
                if hitBattery3 {
                    batteryHPBar(x: 1200, y: 500, hp: BatterHP3,
                                 op: activeBattery == 3 ? batteryBehindOpacity : aBattery3)
                }
                if hitBattery4 {
                    batteryHPBar(x: 900,  y: 700, hp: BatterHP4,
                                 op: activeBattery == 4 ? batteryBehindOpacity : aBattery4)
                }
                if hitBattery5 {
                    batteryHPBar(x: 1000, y: 450, hp: BatterHP5,
                                 op: activeBattery == 5 ? batteryBehindOpacity : aBattery5)
                }

                // ── Attack animation ──────────────────────────
                if attackAnimationVisible {
                    Image("attack\(attackFrame)")
                        .resizable()
                        .interpolation(.none)
                        .frame(width: vs(50), height: vs(50))
                        .position(vp(hitboxPosition1))
                }

                // ── Boss HP bar ───────────────────────────────
                Image(BossHP)
                    .resizable()
                    .interpolation(.none)
                    .frame(width: vs(900), height: vs(150))
                    .position(x: vs(1000) + globalScreenOffset.width,
                              y: vs(900) + globalScreenOffset.height)

                // ── Dead / win screens ────────────────────────
                if deadscrean == 1 && BossHPValue > 0 {
                    Image("DeadScreen")
                        .resizable()
                        .interpolation(.none)
                        .frame(width: vs(2580), height: vs(995))
                        .position(x: vs(1020) + globalScreenOffset.width,
                                  y: vs(500)  + globalScreenOffset.height)
                        .opacity(deadscrean)
                        .onTapGesture { reset = true }
                }
                if BossHPValue == 0 {
                    Image("WIM")
                        .resizable()
                        .interpolation(.none)
                        .frame(width: vs(3600), height: vs(1200))
                        .position(x: vs(1000) + globalScreenOffset.width,
                                  y: vs(500)  + globalScreenOffset.height)
                        .onTapGesture { reset = true }
                }

                // ── Debug overlay ─────────────────────────────
                if showDebug {
                    Circle()
                        .stroke(Color.red, lineWidth: 2)
                        .frame(width: vs(playerRadius) * 2, height: vs(playerRadius) * 2)
                        .position(vp(playerPosition))

                    Rectangle()
                        .stroke(Color.blue, lineWidth: 2)
                        .frame(width: vs(50), height: vs(50))
                        .position(vp(hitboxPosition1))

                    HStack {
                        Text("1:\(BatterHP)").foregroundColor(.orange)
                        Text("2:\(BatterHP2)").foregroundColor(.orange)
                        Text("3:\(BatterHP3)").foregroundColor(.orange)
                        Text("4:\(BatterHP4)").foregroundColor(.orange)
                        Text("5:\(BatterHP5)").foregroundColor(.orange)
                    }

                    ForEach(scaledWalls.indices, id: \.self) { i in
                        let w = scaledWalls[i]
                        Rectangle()
                            .stroke(Color.green, lineWidth: 2)
                            .frame(width: w.width, height: w.height)
                            .position(x: w.midX, y: w.midY)
                    }

                    ForEach(0..<6, id: \.self) { i in
                        let (ax, ay) = bossAttackDesignPos(i)
                        Circle()
                            .stroke(Color.orange, lineWidth: 2)
                            .frame(width: vs(bossAttackRadius) * 2,
                                   height: vs(bossAttackRadius) * 2)
                            .position(x: CGFloat(ax) * S + globalScreenOffset.width,
                                      y: (CGFloat(ay) + bossAttackYOffset) * S + globalScreenOffset.height)
                    }

                    let allBBoxes = [scaledBBox1, scaledBBox2, scaledBBox3,
                                     scaledBBox4, scaledBBox5].flatMap { $0 }
                    ForEach(allBBoxes.indices, id: \.self) { i in
                        Rectangle()
                            .stroke(Color.cyan, lineWidth: 2)
                            .frame(width: allBBoxes[i].width, height: allBBoxes[i].height)
                            .position(x: allBBoxes[i].midX, y: allBBoxes[i].midY)
                    }
                }

                // ── Controls ──────────────────────────────────
                VStack {
                    Spacer()
                    
                    HStack {
                        // Movement joystick
                        ZStack {
                            Image("JoyStickBase")
                                .resizable()
                                .interpolation(.none)
                                .opacity(joystickbOp)
                                .frame(width: vs(joystickSize), height: vs(joystickSize))

                            Image("JoyStick")
                                .resizable()
                                .interpolation(.none)
                                .opacity(JoystickOp)
                                .frame(width: vs(knobSize), height: vs(knobSize))
                                .offset(dragOffset)
                                .gesture(
                                    DragGesture(minimumDistance: 0)
                                        .onChanged { value in
                                            let radius = (vs(joystickSize) - vs(knobSize)) / 2
                                            let dx = value.translation.width
                                            let dy = value.translation.height
                                            let dist   = sqrt(dx*dx + dy*dy)
                                            let clamped = min(dist, radius)
                                            let angle  = atan2(dy, dx)
                                            dragOffset = CGSize(
                                                width:  cos(angle) * clamped,
                                                height: sin(angle) * clamped
                                            )
                                            joystickVector = CGVector(
                                                dx: dragOffset.width  / radius ,
                                                dy: dragOffset.height / radius
                                            )
                                            if !isMoving {
                                                isMoving = true
                                                startMovementLoop()
                                            }
                                        }
                                        .onEnded { _ in
                                            dragOffset     = .zero
                                            joystickVector = .zero
                                            isMoving       = false
                                            stopMovementLoop()
                                            switch lastDirection {
                                            case "down":  MothSprite = "Moth Up"
                                            case "up":    MothSprite = "Moth"
                                            case "right": MothSprite = "Moth Left"
                                            case "left":  MothSprite = "Moth Right"
                                            default:      MothSprite = "Moth"
                                            }
                                        }
                                )
                        }
                        .padding(vs(80))

                        Spacer()

                        // Attack joystick
                        ZStack {
                            Image("Attack control")
                                .resizable()
                                .interpolation(.none)
                                .frame(width: vs(160), height: vs(160))
                                .opacity(ATTACKOP)
                                .gesture(
                                    DragGesture(minimumDistance: 40)
                                        .onChanged { value in
                                            let radius = (vs(joystickSize2) - vs(knobSize2)) / 2
                                            let dx = value.translation.width
                                            let dy = value.translation.height
                                            let dist    = sqrt(dx*dx + dy*dy)
                                            let clamped = min(dist, radius)
                                            let angle   = atan2(dy, dx)
                                            attackOffset = CGSize(
                                                width:  cos(angle) * clamped,
                                                height: sin(angle) * clamped
                                            )
                                            // Divide screen-space drag back to design-space
                                            hitboxPosition1 = CGPoint(
                                                x: playerPosition.x + attackOffset.width  / S,
                                                y: playerPosition.y + attackOffset.height / S
                                            )
                                            hitboxVisible = 1
                                        }
                                        .onEnded { _ in
                                            
                                            hitboxVisible          = 0
                                            if coolDown { return }
                                            attackAnimationVisible = true
                                            attackButtonPressed    = true
                                            startAttackAnimation()
                                            startAttackTimer()
                                            damageBatteryIfHit()
                                            startBatterySwitchTimer()
                                            coolDown = true
                                        }
                                )
                        }
                        .padding(vs(80))
                    }
                }

            }
            // Fill the full screen — ZStack is not clipped, images
            // outside the screen bounds are simply not rendered.
            .frame(width: geo.size.width, height: geo.size.height)
            .onAppear {
                // geo.size is already in the correct landscape orientation
                // because we request landscape below via requestGeometryUpdate.
                // Use the LONG side as width, SHORT side as height.
                let w = max(geo.size.width, geo.size.height)
                let h = min(geo.size.width, geo.size.height)
                let scaleY = h / designHeight
                S = scaleY * 1.05 // 5% bigger
                moveSpeed = 3.0 * S
                startGameLoop()
            }
        }
        // ── Force landscape orientation ───────────────────────────
        .onAppear {
            if let scene = UIApplication.shared.connectedScenes.first
                as? UIWindowScene {
                let pref = UIWindowScene.GeometryPreferences.iOS(
                    interfaceOrientations: .landscape
                )
                scene.requestGeometryUpdate(pref)
                
            }
        }
    }

    // ─────────────────────────────────────────────────────────────
    // SMALL VIEW HELPERS
    // ─────────────────────────────────────────────────────────────

    func bossAttackDesignPos(_ i: Int) -> (Double, Double) {
        switch i {
        case 0: return (randomNumberx,  randomNumbery)
        case 1: return (randomNumber2x, randomNumber2y)
        case 2: return (randomNumber3x, randomNumber3y)
        case 3: return (randomNumber4x, randomNumber4y)
        case 4: return (randomNumber5x, randomNumber5y)
        default: return (randomNumber6x, randomNumber6y)
        }
    }

    @ViewBuilder
    func batteryView(sprite: String, x: CGFloat, y: CGFloat, opacity: Double) -> some View {
        Image(sprite)
            .resizable()
            .interpolation(.none)
            .frame(width: vs(200), height: vs(400))
            .position(x: vs(x) + globalScreenOffset.width, y: vs(y) + globalScreenOffset.height)
            .opacity(opacity)
    }

    @ViewBuilder
    func mothBatteryView(sprite: String, y: CGFloat) -> some View {
        Image(sprite)
            .resizable()
            .interpolation(.none)
            .frame(width: vs(200), height: vs(400))
            .position(x: vs(1600) + globalScreenOffset.width, y: vs(y) + globalScreenOffset.height)
    }

    @ViewBuilder
    func batteryHPBar(x: CGFloat, y: CGFloat, hp: Double, op: Double) -> some View {
        Rectangle()
            .foregroundColor(.gray)
            .frame(width: vs(210), height: vs(40))
            .position(x: vs(x) + globalScreenOffset.width, y: vs(y) + globalScreenOffset.height)
            .offset(CGSize(width: 0, height: -vs(65)))
            .opacity(op)
        Rectangle()
            .foregroundColor(.black)
            .frame(width: vs(200), height: vs(30))
            .position(x: vs(x) + globalScreenOffset.width, y: vs(y) + globalScreenOffset.height)
            .offset(CGSize(width: 0, height: -vs(65)))
            .opacity(op)
        Rectangle()
            .foregroundColor(.cyan)
            .frame(width: CGFloat(hp) * S, height: vs(30))
            .position(x: vs(x) + globalScreenOffset.width, y: vs(y) + globalScreenOffset.height)
            .offset(CGSize(width: 0, height: -vs(65)))
            .opacity(op)
    }

    // ─────────────────────────────────────────────────────────────
    // GAME LOOP
    // RULE: read/write playerPosition, BossPos, hitboxPosition1,
    // randomNumber*, ProtecX/Y always in design-space.
    // ─────────────────────────────────────────────────────────────
    @MainActor
    func startGameLoop() {
        gameTimer?.invalidate()
        gameTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true) { _ in
            Task { @MainActor in
                if phase2 { Phase2() }

                // moveSpeed is already scaled (3.0 * S), so displacement
                // lands in screen-space — divide back to design-space.
                let dx = joystickVector.dx * moveSpeed / S
                let dy = joystickVector.dy * moveSpeed / S

                var blockedByWall = false
                if let scene = UIApplication.shared.connectedScenes.first
                    as? UIWindowScene {
                    let pref = UIWindowScene.GeometryPreferences.iOS(
                        interfaceOrientations: .landscape
                    )
                    scene.requestGeometryUpdate(pref)
                    
                }
                let nextX = CGPoint(x: playerPosition.x + dx, y: playerPosition.y - 13.2)
                if !playerCircleCollides(at: nextX) {
                    playerPosition.x += dx
                } else { blockedByWall = true }

                let nextY = CGPoint(x: playerPosition.x, y: playerPosition.y + dy - 13.2)
                if !playerCircleCollides(at: nextY) {
                    playerPosition.y += dy
                } else { blockedByWall = true }

                applyWallDamageIfNeeded(blocked: blockedByWall)
                applyBossAttackDamage()
                updateBatteryTransparency()
                inProtec()

                if mothInPro == false && Bigtack { MothHP -= 100000 }

                if MothHP <= 0 {
                    deadscrean = 1
                    joystickbOp = 0; JoystickOp = 0; ATTACKOP = 0; moveSpeed = 0
                }
                if BossHPValue == 0 {
                    joystickbOp = 0; JoystickOp = 0; ATTACKOP = 0; moveSpeed = 0
                }
                
                if BossHPValue > 3 {
                    phase2 = false
                }

                if reset { performReset() }

                // Battery hit visibility
                if BatterHP  < 200 && BatterHP  > 0 { hitBattery1 = true }
                if BatterHP2 < 200 && BatterHP2 > 0 { hitBattery2 = true }
                if BatterHP3 < 200 && BatterHP3 > 0 { hitBattery3 = true }
                if BatterHP4 < 200 && BatterHP4 > 0 { hitBattery4 = true }
                if BatterHP5 < 200 && BatterHP5 > 0 { hitBattery5 = true }

                // Active battery opacity
                switch activeBattery {
                case 1: aBattery1=1; aBattery2=0; aBattery3=0; aBattery4=0; aBattery5=0
                case 2: aBattery1=0; aBattery2=1; aBattery3=0; aBattery4=0; aBattery5=0
                case 3: aBattery1=0; aBattery2=0; aBattery3=1; aBattery4=0; aBattery5=0
                case 4: aBattery1=0; aBattery2=0; aBattery3=0; aBattery4=1; aBattery5=0
                case 5: aBattery1=0; aBattery2=0; aBattery3=0; aBattery4=0; aBattery5=1
                default: break
                }

                // Battery defeat + boss HP
                if BatterHP  <= 0 && MothBattery1 != "MothBattery" {
                    MothBattery1 = "MothBattery"; BossHPValue -= 1
                    if BatterHP2 > 0 { BatterHP2 = 200; hitBattery2 = false }
                    if BatterHP3 > 0 { BatterHP3 = 200; hitBattery3 = false }
                    if BatterHP4 > 0 { BatterHP4 = 200; hitBattery4 = false }
                    if BatterHP5 > 0 { BatterHP5 = 200; hitBattery5 = false }
                } else if BatterHP <= 0 && activeBattery == 1 { activeBattery = Int.random(in: 1...5) }

                if BatterHP2 <= 0 && MothBattery2 != "MothBattery" {
                    MothBattery2 = "MothBattery"; BossHPValue -= 1
                    if BatterHP  > 0 { BatterHP  = 200; hitBattery1 = false }
                    if BatterHP3 > 0 { BatterHP3 = 200; hitBattery3 = false }
                    if BatterHP4 > 0 { BatterHP4 = 200; hitBattery4 = false }
                    if BatterHP5 > 0 { BatterHP5 = 200; hitBattery5 = false }
                } else if BatterHP2 <= 0 && activeBattery == 2 { activeBattery = Int.random(in: 1...5) }

                if BatterHP3 <= 0 && MothBattery3 != "MothBattery" {
                    MothBattery3 = "MothBattery"; BossHPValue -= 1
                    if BatterHP  > 0 { BatterHP  = 200; hitBattery1 = false }
                    if BatterHP2 > 0 { BatterHP2 = 200; hitBattery2 = false }
                    if BatterHP4 > 0 { BatterHP4 = 200; hitBattery4 = false }
                    if BatterHP5 > 0 { BatterHP5 = 200; hitBattery5 = false }
                } else if BatterHP3 <= 0 && activeBattery == 3 { activeBattery = Int.random(in: 1...5) }

                if BatterHP4 <= 0 && MothBattery4 != "MothBattery" {
                    MothBattery4 = "MothBattery"; BossHPValue -= 1
                    if BatterHP  > 0 { BatterHP  = 200; hitBattery1 = false }
                    if BatterHP2 > 0 { BatterHP2 = 200; hitBattery2 = false }
                    if BatterHP3 > 0 { BatterHP3 = 200; hitBattery3 = false }
                    if BatterHP5 > 0 { BatterHP5 = 200; hitBattery5 = false }
                } else if BatterHP4 <= 0 && activeBattery == 4 { activeBattery = Int.random(in: 1...5) }

                if BatterHP5 <= 0 && MothBattery5 != "MothBattery" {
                    MothBattery5 = "MothBattery"; BossHPValue -= 1
                    if BatterHP  > 0 { BatterHP  = 200; hitBattery1 = false }
                    if BatterHP2 > 0 { BatterHP2 = 200; hitBattery2 = false }
                    if BatterHP3 > 0 { BatterHP3 = 200; hitBattery3 = false }
                    if BatterHP4 > 0 { BatterHP4 = 200; hitBattery4 = false }
                } else if BatterHP5 <= 0 && activeBattery == 5 { activeBattery = Int.random(in: 1...5) }

                switch BossHPValue {
                case 4: BossHP = "HP4"
                case 3: BossHP = "HP3"; phase2 = true
                case 2: BossHP = "HP2"
                case 1: BossHP = "HP1"
                case 0: BossHP = "HP0"
                default: break
                }
            }
        }

        // Boss hover — design-space positions
        bossMovTimer?.invalidate()
        bossMovTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            Task { @MainActor in
                BossPos = (BossPos.y == 151)
                    ? CGPoint(x: 1000, y: 121)
                    : CGPoint(x: 1000, y: 151)
            }
        }

        // Boss sprite flip
        bossSpriteTimer?.invalidate()
        bossSpriteTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            Task { @MainActor in
                bossSprite = (bossSprite == "Boss Frame One") ? "Boss Frame Two" : "Boss Frame One"
            }
        }

        // Boss attack sprite cycle + lightning randomisation
        bossAttackTimer?.invalidate()
        bossAttackTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            Task { @MainActor in
                if attackswithtrue == false && Protec == false {
                    bossAttackSpriteRandom  = Int.random(in: 1...3)
                    bossAttackSpriteRandom2 = Int.random(in: 1...3)
                    bossAttackSpriteRandom3 = Int.random(in: 1...3)
                    bossAttackSpriteRandom4 = Int.random(in: 1...3)
                    bossAttackSpriteRandom5 = Int.random(in: 1...3)
                    bossAttackSpriteRandom6 = Int.random(in: 1...3)
                } else {
                    bossAttackSpriteRandom  = 0; bossAttackSpriteRandom2 = 0
                    bossAttackSpriteRandom3 = 0; bossAttackSpriteRandom4 = 0
                    bossAttackSpriteRandom5 = 0; bossAttackSpriteRandom6 = 0
                }
                bossAttack  = attackSpriteName(bossAttackSpriteRandom)
                bossAttack2 = attackSpriteName(bossAttackSpriteRandom2)
                bossAttack3 = attackSpriteName(bossAttackSpriteRandom3)
                bossAttack4 = attackSpriteName(bossAttackSpriteRandom4)
                bossAttack5 = attackSpriteName(bossAttackSpriteRandom5)
                bossAttack6 = attackSpriteName(bossAttackSpriteRandom6)

                let rands = [
                    bossBigLightSpriteRandom1,  bossBigLightSpriteRandom2,
                    bossBigLightSpriteRandom3,  bossBigLightSpriteRandom4,
                    bossBigLightSpriteRandom5,  bossBigLightSpriteRandom6,
                    bossBigLightSpriteRandom7,  bossBigLightSpriteRandom8,
                    bossBigLightSpriteRandom9,  bossBigLightSpriteRandom10,
                    bossBigLightSpriteRandom11, bossBigLightSpriteRandom12,
                    bossBigLightSpriteRandom13, bossBigLightSpriteRandom14,
                    bossBigLightSpriteRandom15, bossBigLightSpriteRandom16,
                    bossBigLightSpriteRandom17
                ]
                let lnames = rands.map { lightningSpriteName($0) }
                LightningAttak1  = lnames[0];  LightningAttak2  = lnames[1]
                LightningAttak3  = lnames[2];  LightningAttak4  = lnames[3]
                LightningAttak5  = lnames[4];  LightningAttak6  = lnames[5]
                LightningAttak7  = lnames[6];  LightningAttak8  = lnames[7]
                LightningAttak9  = lnames[8];  LightningAttak10 = lnames[9]
                LightningAttak11 = lnames[10]; LightningAttak12 = lnames[11]
                LightningAttak13 = lnames[12]; LightningAttak14 = lnames[13]
                LightningAttak15 = lnames[14]; LightningAttak16 = lnames[15]
                LightningAttak17 = lnames[16]

                bossBigLightSpriteRandom1  = Int.random(in: 1...4)
                bossBigLightSpriteRandom2  = Int.random(in: 1...4)
                bossBigLightSpriteRandom3  = Int.random(in: 1...4)
                bossBigLightSpriteRandom4  = Int.random(in: 1...4)
                bossBigLightSpriteRandom5  = Int.random(in: 1...4)
                bossBigLightSpriteRandom6  = Int.random(in: 1...4)
                bossBigLightSpriteRandom7  = Int.random(in: 1...4)
                bossBigLightSpriteRandom8  = Int.random(in: 1...4)
                bossBigLightSpriteRandom9  = Int.random(in: 1...4)
                bossBigLightSpriteRandom10 = Int.random(in: 1...4)
                bossBigLightSpriteRandom11 = Int.random(in: 1...4)
                bossBigLightSpriteRandom12 = Int.random(in: 1...4)
                bossBigLightSpriteRandom13 = Int.random(in: 1...4)
                bossBigLightSpriteRandom14 = Int.random(in: 1...4)
                bossBigLightSpriteRandom15 = Int.random(in: 1...4)
                bossBigLightSpriteRandom16 = Int.random(in: 1...4)
                bossBigLightSpriteRandom17 = Int.random(in: 1...4)
            }
        }

        bossAttackSwitchTimer2?.invalidate()
        bossAttackSwitchTimer2 = Timer.scheduledTimer(withTimeInterval: 0.4, repeats: true) { _ in
            Task { @MainActor in attackswithtrue = false }
        }

        // Attack position re-randomise — stays in design-space
        bossAttackSwitchTimer?.invalidate()
        bossAttackSwitchTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
            Task { @MainActor in
                if !Protec {
                    randomNumberx  = Double.random(in: 650...1390)
                    randomNumber2x = Double.random(in: 650...1390)
                    randomNumber3x = Double.random(in: 650...1390)
                    randomNumber4x = Double.random(in: 650...1390)
                    randomNumber5x = Double.random(in: 650...1390)
                    randomNumber6x = Double.random(in: 650...1390)
                    randomNumbery  = Double.random(in: 330...750)
                    randomNumber2y = Double.random(in: 330...750)
                    randomNumber3y = Double.random(in: 330...750)
                    randomNumber4y = Double.random(in: 330...750)
                    randomNumber5y = Double.random(in: 330...750)
                    randomNumber6y = Double.random(in: 330...750)
                }
                attackswithtrue = true
            }
        }
    }

    // ─────────────────────────────────────────────────────────────
    // RESET — all values back to original design-space constants
    // ─────────────────────────────────────────────────────────────
    @MainActor
    func performReset() {
        playerPosition  = CGPoint(x: 700,  y: 500)
        hitboxPosition1 = CGPoint(x: 200,  y: 300)
        BossPos         = CGPoint(x: 1000, y: 151)
        dragOffset = .zero; attackOffset = .zero; joystickVector = .zero
        coolDown = false; attackButtonPressed = false
        MothSprite = "Moth"; bossSprite = "Boss Frame One"
        showDebug = false
        MothHP = 50.0
        joystickbOp = 0.3; JoystickOp = 0.8; ATTACKOP = 1.0
        attackAnimationVisible = false; attackFrame = 0; hitboxVisible = 0.0
        bossAttack  = "Boss attack 0"; bossAttack2 = "Boss attack 0"
        bossAttack3 = "Boss attack 0"; bossAttack4 = "Boss attack 0"
        bossAttack5 = "Boss attack 0"; bossAttack6 = "Boss attack 0"
        bossAttackSpriteRandom  = Int.random(in: 1...3)
        bossAttackSpriteRandom2 = Int.random(in: 1...3)
        bossAttackSpriteRandom3 = Int.random(in: 1...3)
        bossAttackSpriteRandom4 = Int.random(in: 1...3)
        bossAttackSpriteRandom5 = Int.random(in: 1...3)
        bossAttackSpriteRandom6 = Int.random(in: 1...3)
        randomNumberx  = Double.random(in: 550...1390)
        randomNumber2x = Double.random(in: 550...1390)
        randomNumber3x = Double.random(in: 550...1390)
        randomNumber4x = Double.random(in: 550...1390)
        randomNumber5x = Double.random(in: 550...1390)
        randomNumber6x = Double.random(in: 550...1390)
        randomNumbery  = Double.random(in: 330...850)
        randomNumber2y = Double.random(in: 330...850)
        randomNumber3y = Double.random(in: 330...850)
        randomNumber4y = Double.random(in: 330...850)
        randomNumber5y = Double.random(in: 330...850)
        randomNumber6y = Double.random(in: 330...850)
        ProtecX = Double.random(in: 650...1390)
        ProtecY = Double.random(in: 430...750)
        isMoving = false; BossHP = "HP5"; deadscrean = 0.0
        Battery  = "BatteryBoss"; Battery2 = "BatteryBoss"; Battery3 = "BatteryBoss"
        Battery4 = "BatteryBoss"; Battery5 = "BatteryBoss"
        activeBattery = Int.random(in: 1...5)
        aBattery1=1.0; aBattery2=1.0; aBattery3=1.0; aBattery4=1.0; aBattery5=1.0
        BatterHP=200; BatterHP2=200; BatterHP3=200; BatterHP4=200; BatterHP5=200
        hitBattery1=false; hitBattery2=false; hitBattery3=false
        hitBattery4=false; hitBattery5=false
        BossHPValue = 5
        MothBattery1=""; MothBattery2=""; MothBattery3=""; MothBattery4=""; MothBattery5=""
        phase2 = false
        LightningAttak1="LightningBeam1";  LightningAttak2="LightningBeam1"
        LightningAttak3="LightningBeam1";  LightningAttak4="LightningBeam1"
        LightningAttak5="LightningBeam1";  LightningAttak6="LightningBeam1"
        LightningAttak7="LightningBeam1";  LightningAttak8="LightningBeam1"
        LightningAttak9="LightningBeam1";  LightningAttak10="LightningBeam1"
        LightningAttak11="LightningBeam1"; LightningAttak12="LightningBeam1"
        LightningAttak13="LightningBeam1"; LightningAttak14="LightningBeam1"
        LightningAttak15="LightningBeam1"; LightningAttak16="LightningBeam1"
        LightningAttak17="LightningBeam1"
        bossBigLightSpriteRandom1  = Int.random(in: 1...4)
        bossBigLightSpriteRandom2  = Int.random(in: 1...4)
        bossBigLightSpriteRandom3  = Int.random(in: 1...4)
        bossBigLightSpriteRandom4  = Int.random(in: 1...4)
        bossBigLightSpriteRandom5  = Int.random(in: 1...4)
        bossBigLightSpriteRandom6  = Int.random(in: 1...4)
        bossBigLightSpriteRandom7  = Int.random(in: 1...4)
        bossBigLightSpriteRandom8  = Int.random(in: 1...4)
        bossBigLightSpriteRandom9  = Int.random(in: 1...4)
        bossBigLightSpriteRandom10 = Int.random(in: 1...4)
        bossBigLightSpriteRandom11 = Int.random(in: 1...4)
        bossBigLightSpriteRandom12 = Int.random(in: 1...4)
        bossBigLightSpriteRandom13 = Int.random(in: 1...4)
        bossBigLightSpriteRandom14 = Int.random(in: 1...4)
        bossBigLightSpriteRandom15 = Int.random(in: 1...4)
        bossBigLightSpriteRandom16 = Int.random(in: 1...4)
        bossBigLightSpriteRandom17 = Int.random(in: 1...4)
        moveSpeed = 3.0 * S
        reset = false
    }

    // ─────────────────────────────────────────────────────────────
    // SPRITE NAME HELPERS
    // ─────────────────────────────────────────────────────────────
    func attackSpriteName(_ n: Int) -> String {
        switch n {
        case 1: return "Boss attack 1"
        case 2: return "Boss attack 2"
        case 3: return "Boss attack 3"
        default: return "Boss attack 0"
        }
    }

    func lightningSpriteName(_ n: Int) -> String {
        switch n {
        case 2: return "LightningBeam2"
        case 3: return "LightningBeam3"
        case 4: return "LightningBeam4"
        default: return "LightningBeam1"
        }
    }

    // ─────────────────────────────────────────────────────────────
    // MOVEMENT ANIMATION LOOP
    // ─────────────────────────────────────────────────────────────
    @MainActor
    func startMovementLoop() {
        movementLoopTimer?.invalidate()
        movementLoopTimer = Timer.scheduledTimer(withTimeInterval: 0.15, repeats: true) { _ in
            Task { @MainActor in
                if !isMoving { return }
                let dx = joystickVector.dx
                let dy = joystickVector.dy
                if abs(dy) > abs(dx) {
                    lastDirection = dy > 0 ? "up" : "down"
                } else {
                    lastDirection = dx > 0 ? "right" : "left"
                }
                updateMothSpriteForDirection()
            }
        }
    }

    @MainActor
    func stopMovementLoop() {
        movementLoopTimer?.invalidate()
        movementLoopTimer = nil
    }

    // ─────────────────────────────────────────────────────────────
    // SPRITE SYSTEM
    // ─────────────────────────────────────────────────────────────
    @MainActor
    func updateMothSpriteForDirection() {
        animationFrame = (animationFrame + 1) % 3
        switch lastDirection {
        case "up":    MothSprite = ["Moth", "Moth Run Right", "Moth Run Left"][animationFrame]
        case "down":  MothSprite = ["Moth Up", "Moth Up Right", "Moth Up Left"][animationFrame]
        case "right": MothSprite = ["Moth Left", "Moth Left Up", "Moth Left Down"][animationFrame]
        case "left":  MothSprite = ["Moth Right", "Moth Right Up", "Moth Right Down"][animationFrame]
        default:      MothSprite = "Moth"
        }
    }

    // ─────────────────────────────────────────────────────────────
    // ATTACK ANIMATION
    // ─────────────────────────────────────────────────────────────
    @MainActor
    func startAttackAnimation() {
        attackFrame = 1
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: false) { _ in
            Task { @MainActor in attackFrame = 2 }
        }
        Timer.scheduledTimer(withTimeInterval: 0.2, repeats: false) { _ in
            Task { @MainActor in attackFrame = 3 }
        }
    }

    @MainActor
    func startAttackTimer() {
        Timer.scheduledTimer(withTimeInterval: 0.4, repeats: false) { _ in
            Task { @MainActor in
                attackButtonPressed = false; attackOffset = .zero
                hitboxVisible = 0; attackAnimationVisible = false; attackFrame = 0
            }
        }
        Timer.scheduledTimer(withTimeInterval: 0.8, repeats: false) { _ in
            Task { @MainActor in coolDown = false }
        }
    }

    // ─────────────────────────────────────────────────────────────
    // COLLISION HELPERS
    // Positions are design-space; multiply by S before comparing
    // against scaledWalls / scaledBBox which are screen-space.
    // ─────────────────────────────────────────────────────────────
    @MainActor
    func playerHitbox(at pos: CGPoint) -> CGRect {
        CGRect(
            x: pos.x * S + globalScreenOffset.width - vs(playerSize) / 2,
            y: pos.y * S + globalScreenOffset.height - vs(playerSize) / 2,
            width: vs(playerSize), height: vs(playerSize)
        )
    }

    @MainActor
    func applyWallDamageIfNeeded(blocked: Bool) {
        guard blocked else { return }
        let now = Date().timeIntervalSince1970
        if now - lastWallDamageTime >= wallDamageCooldown {
            MothHP = max(0, MothHP - wallDamageAmount)
            lastWallDamageTime = now
        }
    }

    @MainActor
    func updateBatteryTransparency() {
        let pr = playerHitbox(at: playerPosition)
        let box: CGRect?
        switch activeBattery {
        case 1: box = scaledBBox1.first
        case 2: box = scaledBBox2.first
        case 3: box = scaledBBox3.first
        case 4: box = scaledBBox4.first
        case 5: box = scaledBBox5.first
        default: box = nil
        }
        if let b = box { batteryBehindOpacity = b.intersects(pr) ? 0.6 : 1.0 }
    }

    @MainActor
    func inProtec() {
        let mothRect = playerHitbox(at: playerPosition)
        let protecBox = CGRect(
            x: (ProtecX - 75) * S + globalScreenOffset.width,
            y: (ProtecY - 75) * S + globalScreenOffset.height,
            width: vs(150), height: vs(150)
        )
        mothInPro = protecBox.intersects(mothRect)
    }

    @MainActor
    func circlesIntersect(_ a: CGPoint, _ ar: CGFloat, _ b: CGPoint, _ br: CGFloat) -> Bool {
        let dx = a.x - b.x; let dy = a.y - b.y
        return dx*dx + dy*dy <= (ar + br) * (ar + br)
    }

    @MainActor
    func applyBossAttackDamage() {
        let now = Date().timeIntervalSince1970
        guard now - lastBossHitTime > bossAttackCooldown else { return }
        // Convert design-space player position to screen-space for comparison
        let pc = CGPoint(x: playerPosition.x * S + globalScreenOffset.width,
                         y: playerPosition.y * S + globalScreenOffset.height)
        for i in 0..<6 {
            let (ax, ay) = bossAttackDesignPos(i)
            let ac = CGPoint(x: CGFloat(ax) * S + globalScreenOffset.width,
                             y: (CGFloat(ay) + bossAttackYOffset) * S + globalScreenOffset.height)
            if circlesIntersect(pc, vs(playerRadius), ac, vs(bossAttackRadius)) {
                if !attackswithtrue && !Protec {
                    MothHP = max(0, MothHP - bossAttackDamage)
                    lastBossHitTime = now
                    break
                }
            }
        }
    }

    @MainActor
    func circleIntersectsRect(center: CGPoint, radius: CGFloat, rect: CGRect) -> Bool {
        let cx = min(max(center.x, rect.minX), rect.maxX)
        let cy = min(max(center.y, rect.minY), rect.maxY)
        let dx = center.x - cx; let dy = center.y - cy
        return dx*dx + dy*dy <= radius * radius
    }

    @MainActor
    func playerCircleCollides(at pos: CGPoint) -> Bool {
        // pos is design-space; convert to screen-space for wall test
        let sc = CGPoint(x: pos.x * S + globalScreenOffset.width,
                         y: pos.y * S + globalScreenOffset.height)
        return scaledWalls.contains {
            circleIntersectsRect(center: sc, radius: vs(playerRadius), rect: $0)
        }
    }

    // ─────────────────────────────────────────────────────────────
    // BATTERY DAMAGE
    // ─────────────────────────────────────────────────────────────
    @MainActor
    func damageBatteryIfHit() {
        // hitboxPosition1 is design-space; convert to screen-space
        let sc = CGPoint(x: hitboxPosition1.x * S + globalScreenOffset.width,
                         y: hitboxPosition1.y * S + globalScreenOffset.height)
        let r = CGRect(x: sc.x - vs(attackSize)/2, y: sc.y - vs(attackSize)/2,
                       width: vs(attackSize), height: vs(attackSize))
        switch activeBattery {
        case 1: if scaledBBox1.first?.intersects(r) == true { BatterHP  -= 15 }
        case 2: if scaledBBox2.first?.intersects(r) == true { BatterHP2 -= 15 }
        case 3: if scaledBBox3.first?.intersects(r) == true { BatterHP3 -= 15 }
        case 4: if scaledBBox4.first?.intersects(r) == true { BatterHP4 -= 15 }
        case 5: if scaledBBox5.first?.intersects(r) == true { BatterHP5 -= 15 }
        default: break
        }
    }

    @MainActor
    func startBatterySwitchTimer() {
        batterySwitchTimer?.invalidate()
        batterySwitchTimer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: false) { _ in
            Task { @MainActor in activeBattery = Int.random(in: 1...5) }
        }
    }

    // ─────────────────────────────────────────────────────────────
    // PHASE 2
    // ─────────────────────────────────────────────────────────────
    @MainActor
    func Phase2() {
        phase2 = false

        BigAttackShieldTimer?.invalidate()
        BigAttackShieldTimer = Timer.scheduledTimer(
            withTimeInterval: biggattackTime - 3, repeats: true) { _ in
            Task { @MainActor in Protec = true }
        }

        BigAttackTimer?.invalidate()
        BigAttackTimer = Timer.scheduledTimer(
            withTimeInterval: biggattackTime, repeats: true) { _ in
            Task { @MainActor in Bigtack = true }
        }

        BigAttackEndTimer?.invalidate()
        BigAttackEndTimer = Timer.scheduledTimer(
            withTimeInterval: biggattackTime + 5, repeats: true) { _ in
            Task { @MainActor in
                Protec  = false; Bigtack = false
                ProtecX = Double.random(in: 650...1390)   // design-space
                ProtecY = Double.random(in: 430...750)
                biggattackTime = Double.random(in: 10...40)
                phase2  = true
            }
        }
    }
}

#Preview {
    ContentView()
}

