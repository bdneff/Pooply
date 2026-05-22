//
//  SplashVideoView.swift
//  Pooply
//
//  Cold-launch splash. Plays pooply.mp4 fullscreen on top of brand blue,
//  loops while visible, and auto-dismisses after 2.5s (or on tap).
//  Uses AVPlayerLayer wrapped in UIViewRepresentable so there's no
//  AVKit chrome — pure pixels, edge-to-edge.
//

import SwiftUI
import AVKit

// MARK: - Player holder (retains AVQueuePlayer + Looper across re-renders)

final class SplashPlayerHolder: ObservableObject {
    let player: AVQueuePlayer
    private var looper: AVPlayerLooper?

    init() {
        let queuePlayer = AVQueuePlayer()
        queuePlayer.isMuted = true
        queuePlayer.actionAtItemEnd = .advance
        self.player = queuePlayer

        guard let url = Bundle.main.url(forResource: "pooply", withExtension: "mp4") else {
            return
        }
        let item = AVPlayerItem(url: url)
        self.looper = AVPlayerLooper(player: queuePlayer, templateItem: item)
    }

    func play() {
        player.seek(to: .zero)
        player.play()
    }

    func stop() {
        player.pause()
    }
}

// MARK: - UIViewRepresentable hosting AVPlayerLayer (no controls)

struct SplashPlayerLayerView: UIViewRepresentable {
    let player: AVPlayer

    func makeUIView(context: Context) -> PlayerContainerView {
        let view = PlayerContainerView()
        view.backgroundColor = .clear
        view.playerLayer.player = player
        view.playerLayer.videoGravity = .resizeAspectFill
        return view
    }

    func updateUIView(_ uiView: PlayerContainerView, context: Context) {
        uiView.playerLayer.player = player
        uiView.playerLayer.videoGravity = .resizeAspectFill
    }

    final class PlayerContainerView: UIView {
        override static var layerClass: AnyClass { AVPlayerLayer.self }
        var playerLayer: AVPlayerLayer { layer as! AVPlayerLayer }
    }
}

// MARK: - Splash

struct SplashVideoView: View {
    @Binding var isPresented: Bool
    @StateObject private var holder = SplashPlayerHolder()

    // Exact background color sampled from the pooply.mp4 frame so the video
    // sits flush against the splash background with no visible seam.
    private static let videoBackground = Color(red: 136/255, green: 218/255, blue: 252/255) // #88DAFC

    var body: some View {
        ZStack {
            // Match the video's own background so the edges of the rendered
            // square blend invisibly into the surrounding fill.
            Self.videoBackground
                .ignoresSafeArea()

            // Video plays in a centered, capped square — smaller than fullscreen
            // so the brand reads like a logo, not a fullscreen takeover.
            SplashPlayerLayerView(player: holder.player)
                .aspectRatio(1, contentMode: .fit)
                .frame(maxWidth: 280, maxHeight: 280)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            dismiss()
        }
        .onAppear {
            holder.play()
            Task {
                try? await Task.sleep(nanoseconds: 2_500_000_000)
                await MainActor.run { dismiss() }
            }
        }
        .onDisappear {
            holder.stop()
        }
        .preferredColorScheme(.light)
        .ignoresSafeArea()
    }

    private func dismiss() {
        guard isPresented else { return }
        withAnimation(.easeInOut(duration: 0.35)) {
            isPresented = false
        }
    }
}
