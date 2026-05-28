import AppKit

struct NativeGlassBackplateDescriptor {
    let surface: HUDResolvedSurface
    let role: GlassSurfaceRole
    let status: HUDStatusTone
    let readability: GlassReadabilityStyle
    let cornerRadius: CGFloat
}

final class NativeGlassBackplate {
    private weak var owner: NSView?
    private var glassView: NSView?
    private var glassViewIsNativeGlass = false
    private var scrimView: GlassScrimView?

    init(owner: NSView) {
        self.owner = owner
    }

    func configureIfNeeded(
        surface: HUDResolvedSurface,
        role: GlassSurfaceRole,
        status: HUDStatusTone,
        readability: GlassReadabilityStyle,
        cornerRadius: CGFloat
    ) {
        remove()
        guard surface == .nativeGlass,
              let owner,
              let glass = NativeGlassEffectBridge.makeGlassView(
                  frame: owner.bounds,
                  cornerRadius: cornerRadius,
                  tintColor: NativeGlassSurfaceStyle.tintColor(status: status, readability: readability)
              ) else {
            return
        }

        glass.translatesAutoresizingMaskIntoConstraints = false
        owner.addSubview(glass, positioned: .below, relativeTo: nil)
        pinToOwner(glass, owner: owner)

        let scrim = GlassScrimView()
        scrim.translatesAutoresizingMaskIntoConstraints = false
        scrim.cornerRadius = cornerRadius
        applyOverlay(to: scrim, role: role, status: status, readability: readability)
        owner.addSubview(scrim, positioned: .above, relativeTo: glass)
        pinToOwner(scrim, owner: owner)

        glassView = glass
        glassViewIsNativeGlass = true
        scrimView = scrim
    }

    func configureIfNeeded(_ descriptor: NativeGlassBackplateDescriptor) {
        configureIfNeeded(
            surface: descriptor.surface,
            role: descriptor.role,
            status: descriptor.status,
            readability: descriptor.readability,
            cornerRadius: descriptor.cornerRadius
        )
    }

    func updateAppearance(
        role: GlassSurfaceRole,
        status: HUDStatusTone,
        readability: GlassReadabilityStyle
    ) {
        if glassViewIsNativeGlass, let glassView {
            NativeGlassEffectBridge.updateAppearance(
                of: glassView,
                tintColor: NativeGlassSurfaceStyle.tintColor(status: status, readability: readability)
            )
        } else if let effect = glassView as? NSVisualEffectView {
            effect.alphaValue = readability.materialAlpha
            effect.appearance = NSAppearance(named: .darkAqua)
        }
        applyOverlay(to: scrimView, role: role, status: status, readability: readability)
    }

    func updateAppearance(_ descriptor: NativeGlassBackplateDescriptor) {
        updateAppearance(
            role: descriptor.role,
            status: descriptor.status,
            readability: descriptor.readability
        )
    }

    func updateCornerRadius(_ cornerRadius: CGFloat) {
        if glassViewIsNativeGlass, let glassView {
            NativeGlassEffectBridge.updateCornerRadius(cornerRadius, of: glassView)
        } else if let effect = glassView as? NSVisualEffectView {
            effect.layer?.cornerRadius = cornerRadius
        }
        scrimView?.cornerRadius = cornerRadius
    }

    func updateCornerRadius(_ descriptor: NativeGlassBackplateDescriptor) {
        updateCornerRadius(descriptor.cornerRadius)
    }

    private func remove() {
        glassView?.removeFromSuperview()
        glassView = nil
        glassViewIsNativeGlass = false
        scrimView?.removeFromSuperview()
        scrimView = nil
    }

    private func applyOverlay(
        to scrim: GlassScrimView?,
        role: GlassSurfaceRole,
        status: HUDStatusTone,
        readability: GlassReadabilityStyle
    ) {
        guard let scrim else { return }
        scrim.color = NativeGlassSurfaceStyle.overlayColor(status: status, readability: readability)
        scrim.topSheenAlpha = NativeGlassSurfaceStyle.topSheenAlpha(role: role, status: status)
        scrim.bottomShadeAlpha = NativeGlassSurfaceStyle.bottomShadeAlpha(role: role, status: status)
        scrim.innerRimAlpha = NativeGlassSurfaceStyle.innerRimAlpha(status: status, role: role)
    }

    private func pinToOwner(_ view: NSView, owner: NSView) {
        NSLayoutConstraint.activate([
            view.leadingAnchor.constraint(equalTo: owner.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: owner.trailingAnchor),
            view.topAnchor.constraint(equalTo: owner.topAnchor),
            view.bottomAnchor.constraint(equalTo: owner.bottomAnchor)
        ])
    }
}

private enum NativeGlassEffectBridge {
    private static let className = "NSGlassEffectView"

    static func makeGlassView(frame: CGRect, cornerRadius: CGFloat, tintColor: NSColor?) -> NSView? {
        guard let viewClass = NSClassFromString(className) as? NSView.Type else {
            return nil
        }
        let view = viewClass.init(frame: frame)
        setRegularStyle(on: view)
        updateCornerRadius(cornerRadius, of: view)
        updateAppearance(of: view, tintColor: tintColor)
        return view
    }

    static func updateAppearance(of view: NSView, tintColor: NSColor?) {
        view.setValue(tintColor, forKey: "tintColor")
        view.alphaValue = 1
    }

    static func updateCornerRadius(_ cornerRadius: CGFloat, of view: NSView) {
        view.setValue(NSNumber(value: Double(cornerRadius)), forKey: "cornerRadius")
    }

    private static func setRegularStyle(on view: NSView) {
        view.setValue(NSNumber(value: 0), forKey: "style")
    }
}
