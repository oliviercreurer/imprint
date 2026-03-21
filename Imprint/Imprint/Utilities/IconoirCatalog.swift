import SwiftUI
import Iconoir

/// A curated catalog of Iconoir icons available for user-defined categories.
///
/// Stores icons by their canonical kebab-case name (matching the Iconoir website),
/// which is also the value persisted in SwiftData's `Category.iconName`.
/// Provides a lookup from name → SwiftUI `Image` at render time.
enum IconoirCatalog {

    /// All curated icon names in display order.
    static let allNames: [String] = [
        // Media & Entertainment
        "cinema-old", "movie", "tv", "modern-tv", "video-camera",
        "camera", "media-image", "media-image-list", "microphone",
        "sound-high", "podcast", "music-double-note", "compact-disc", "album",
        "book", "book-stack", "page", "empty-page", "journal-page",
        "page-flip", "multiple-pages", "keyframe",

        // Sports & Activities
        "basketball", "fishing", "trekking", "archery",
        "bicycle", "tournament",

        // Creative & Design
        "palette", "color-wheel", "design-pencil", "design-nib",
        "frame-simple", "selective-tool", "lens", "cut", "angle-tool",

        // Tech & Dev
        "code", "puzzle", "hard-drive", "server",
        "database", "cable-tag", "network", "internet", "at-sign",
        "app-window", "mac-os-window", "square-cursor", "system-restart",

        // Documents & Organization
        "reports", "align-left", "list", "attachment",
        "archive", "folder", "bookmark", "pin", "post",

        // Business & Finance
        "suitcase", "wallet", "apple-wallet", "dollar-circle", "bank",

        // Places & Buildings
        "city", "building", "home-alt", "shop-four-tiles",

        // Food & Drink
        "pizza-slice", "apple", "cutlery", "coffee-cup", "fridge",

        // Gaming
        "playstation-gamepad", "dice-six", "arcade", "pokeball",

        // People & Identity
        "profile-circle", "fingerprint", "voice", "glasses", "pants-pockets",

        // Emoji
        "emoji", "emoji-satisfied", "emoji-quite", "emoji-really",

        // Travel & Navigation
        "airplane", "car", "train", "maps-arrow", "map-pin", "map",

        // Nature & Weather
        "tree", "sun-light", "snow-flake", "half-moon", "flash",

        // Time
        "wristwatch", "timer", "clock", "hourglass", "calendar",

        // Shapes
        "circle", "rhombus", "hexagon", "square", "triangle",
        "star", "heart",

        // Objects & Misc
        "cart", "shopping-bag", "flask",
        "planet-alt", "magnet", "sine-wave", "square-wave", "infinite",
        "brain", "light-bulb", "box", "lock", "wrench",
        "view-grid", "table-rows", "path-arrow", "settings-profiles",
        "dashboard-dots",
    ]

    /// Returns the SwiftUI `Image` for a given icon name.
    /// Falls back to a generic square icon if the name isn't found.
    static func image(for name: String) -> Image {
        iconMap[name] ?? Iconoir.square.asImage
    }

    // MARK: - Private Lookup Table

    /// Maps kebab-case icon names to their Iconoir SwiftUI `Image`.
    private static let iconMap: [String: Image] = [
        // Media & Entertainment
        "cinema-old":       Iconoir.cinemaOld.asImage,
        "movie":            Iconoir.movie.asImage,
        "tv":               Iconoir.tv.asImage,
        "modern-tv":        Iconoir.modernTv.asImage,
        "video-camera":     Iconoir.videoCamera.asImage,
        "camera":           Iconoir.camera.asImage,
        "media-image":      Iconoir.mediaImage.asImage,
        "media-image-list": Iconoir.mediaImageList.asImage,
        "microphone":       Iconoir.microphone.asImage,
        "sound-high":       Iconoir.soundHigh.asImage,
        "podcast":          Iconoir.podcast.asImage,
        "music-double-note": Iconoir.musicDoubleNote.asImage,
        "compact-disc":     Iconoir.compactDisc.asImage,
        "album":            Iconoir.album.asImage,
        "book":             Iconoir.book.asImage,
        "book-stack":       Iconoir.bookStack.asImage,
        "page":             Iconoir.page.asImage,
        "empty-page":       Iconoir.emptyPage.asImage,
        "journal-page":     Iconoir.journalPage.asImage,
        "page-flip":        Iconoir.pageFlip.asImage,
        "multiple-pages":   Iconoir.multiplePages.asImage,
        "keyframe":         Iconoir.keyframe.asImage,

        // Sports & Activities
        "basketball":       Iconoir.basketball.asImage,
        "fishing":          Iconoir.fishing.asImage,
        "trekking":         Iconoir.trekking.asImage,
        "archery":          Iconoir.archery.asImage,
        "bicycle":          Iconoir.bicycle.asImage,
        "tournament":       Iconoir.tournament.asImage,

        // Creative & Design
        "palette":          Iconoir.palette.asImage,
        "color-wheel":      Iconoir.colorWheel.asImage,
        "design-pencil":    Iconoir.designPencil.asImage,
        "design-nib":       Iconoir.designNib.asImage,
        "frame-simple":     Iconoir.frameSimple.asImage,
        "selective-tool":   Iconoir.selectiveTool.asImage,
        "lens":             Iconoir.lens.asImage,
        "cut":              Iconoir.cut.asImage,
        "angle-tool":       Iconoir.angleTool.asImage,

        // Tech & Dev
        "code":             Iconoir.code.asImage,
        "puzzle":           Iconoir.puzzle.asImage,
        "hard-drive":       Iconoir.hardDrive.asImage,
        "server":           Iconoir.server.asImage,
        "database":         Iconoir.database.asImage,
        "cable-tag":        Iconoir.cableTag.asImage,
        "network":          Iconoir.network.asImage,
        "internet":         Iconoir.internet.asImage,
        "at-sign":          Iconoir.atSign.asImage,
        "app-window":       Iconoir.appWindow.asImage,
        "mac-os-window":    Iconoir.macOsWindow.asImage,
        "square-cursor":    Iconoir.squareCursor.asImage,
        "system-restart":   Iconoir.systemRestart.asImage,

        // Documents & Organization
        "reports":          Iconoir.reports.asImage,
        "align-left":       Iconoir.alignLeft.asImage,
        "list":             Iconoir.list.asImage,
        "attachment":       Iconoir.attachment.asImage,
        "archive":          Iconoir.archive.asImage,
        "folder":           Iconoir.folder.asImage,
        "bookmark":         Iconoir.bookmark.asImage,
        "pin":              Iconoir.pin.asImage,
        "post":             Iconoir.post.asImage,

        // Business & Finance
        "suitcase":         Iconoir.suitcase.asImage,
        "wallet":           Iconoir.wallet.asImage,
        "apple-wallet":     Iconoir.appleWallet.asImage,
        "dollar-circle":    Iconoir.dollarCircle.asImage,
        "bank":             Iconoir.bank.asImage,

        // Places & Buildings
        "city":             Iconoir.city.asImage,
        "building":         Iconoir.building.asImage,
        "home-alt":         Iconoir.homeAlt.asImage,
        "shop-four-tiles":  Iconoir.shopFourTiles.asImage,

        // Food & Drink
        "pizza-slice":      Iconoir.pizzaSlice.asImage,
        "apple":            Iconoir.apple.asImage,
        "cutlery":          Iconoir.cutlery.asImage,
        "coffee-cup":       Iconoir.coffeeCup.asImage,
        "fridge":           Iconoir.fridge.asImage,

        // Gaming
        "playstation-gamepad": Iconoir.playstationGamepad.asImage,
        "dice-six":         Iconoir.diceSix.asImage,
        "arcade":           Iconoir.arcade.asImage,
        "pokeball":         Iconoir.pokeball.asImage,

        // People & Identity
        "profile-circle":   Iconoir.profileCircle.asImage,
        "fingerprint":      Iconoir.fingerprint.asImage,
        "voice":            Iconoir.voice.asImage,
        "glasses":          Iconoir.glasses.asImage,
        "pants-pockets":    Iconoir.pantsPockets.asImage,

        // Emoji
        "emoji":            Iconoir.emoji.asImage,
        "emoji-satisfied":  Iconoir.emojiSatisfied.asImage,
        "emoji-quite":      Iconoir.emojiQuite.asImage,
        "emoji-really":     Iconoir.emojiReally.asImage,

        // Travel & Navigation
        "airplane":         Iconoir.airplane.asImage,
        "car":              Iconoir.car.asImage,
        "train":            Iconoir.train.asImage,
        "maps-arrow":       Iconoir.mapsArrow.asImage,
        "map-pin":          Iconoir.mapPin.asImage,
        "map":              Iconoir.map.asImage,

        // Nature & Weather
        "tree":             Iconoir.tree.asImage,
        "sun-light":        Iconoir.sunLight.asImage,
        "snow-flake":       Iconoir.snowFlake.asImage,
        "half-moon":        Iconoir.halfMoon.asImage,
        "flash":            Iconoir.flash.asImage,

        // Time
        "wristwatch":       Iconoir.wristwatch.asImage,
        "timer":            Iconoir.timer.asImage,
        "clock":            Iconoir.clock.asImage,
        "hourglass":        Iconoir.hourglass.asImage,
        "calendar":         Iconoir.calendar.asImage,

        // Shapes
        "circle":           Iconoir.circle.asImage,
        "rhombus":          Iconoir.rhombus.asImage,
        "hexagon":          Iconoir.hexagon.asImage,
        "square":           Iconoir.square.asImage,
        "triangle":         Iconoir.triangle.asImage,
        "star":             Iconoir.star.asImage,
        "heart":            Iconoir.heart.asImage,

        // Objects & Misc
        "cart":             Iconoir.cart.asImage,
        "shopping-bag":     Iconoir.shoppingBag.asImage,
        "flask":            Iconoir.flask.asImage,
        "planet-alt":       Iconoir.planetAlt.asImage,
        "magnet":           Iconoir.magnet.asImage,
        "sine-wave":        Iconoir.sineWave.asImage,
        "square-wave":      Iconoir.squareWave.asImage,
        "infinite":         Iconoir.infinite.asImage,
        "brain":            Iconoir.brain.asImage,
        "light-bulb":       Iconoir.lightBulb.asImage,
        "box":              Iconoir.box.asImage,
        "lock":             Iconoir.lock.asImage,
        "wrench":           Iconoir.wrench.asImage,
        "view-grid":        Iconoir.viewGrid.asImage,
        "table-rows":       Iconoir.tableRows.asImage,
        "path-arrow":       Iconoir.pathArrow.asImage,
        "settings-profiles": Iconoir.settingsProfiles.asImage,
        "dashboard-dots":   Iconoir.dashboardDots.asImage,
    ]
}
