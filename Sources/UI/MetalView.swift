import SwiftUI
import MetalKit

// MARK: - Uniforms (must mirror AuroraUniforms in NotchShader.metal)

private struct AuroraUniforms {
    var time:      Float
    var intensity: Float
}

// MARK: - MetalView

/// NSViewRepresentable that renders the aurora shader as a transparent layer.
///
/// Hit-testing is disabled so mouse events pass straight through to SwiftUI
/// views behind this one.  Rendered at 30 fps to preserve battery.
struct MetalView: NSViewRepresentable {

    var intensity: Float

    // MARK: NSViewRepresentable

    func makeNSView(context: Context) -> MTKView {
        let view = PassthroughMTKView()

        guard let device = context.coordinator.device else {
            // Metal unavailable — return a plain transparent view.
            return view
        }

        view.device               = device
        view.delegate             = context.coordinator

        // 30 fps cap — more than enough for a background ambiance effect.
        view.preferredFramesPerSecond = 30
        view.enableSetNeedsDisplay    = false   // continuous rendering
        view.isPaused                 = false

        // Transparent background so the black pill shows through.
        view.clearColor = MTLClearColorMake(0, 0, 0, 0)
        view.colorPixelFormat = .bgra8Unorm
        view.isOpaque = false
        view.layer?.isOpaque = false

        return view
    }

    func updateNSView(_ nsView: MTKView, context: Context) {
        context.coordinator.intensity = intensity
        // Pause rendering when the aurora is fully off to save CPU/GPU cycles.
        // The MTKView resumes automatically when intensity rises above 0.
        nsView.isPaused = (intensity == 0)
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    // MARK: - PassthroughMTKView

    private class PassthroughMTKView: MTKView {
        // Return nil so no mouse event is consumed by the Metal layer.
        override func hitTest(_ point: NSPoint) -> NSView? { nil }
    }

    // MARK: - Coordinator / renderer

    final class Coordinator: NSObject, MTKViewDelegate {

        let device: MTLDevice? = MTLCreateSystemDefaultDevice()
        var intensity: Float   = 0

        private var commandQueue:  MTLCommandQueue?
        private var pipelineState: MTLRenderPipelineState?
        private let startTime      = Date()

        override init() {
            super.init()
            buildPipeline()
        }

        private func buildPipeline() {
            guard let device else { return }

            // The .metal file is compiled by Xcode/SPM into the app's default
            // Metal library, so makeDefaultLibrary() finds aurora_vert/_frag.
            guard let library = device.makeDefaultLibrary() else {
                NSLog("[MetalView] makeDefaultLibrary() returned nil — shader not compiled into bundle")
                return
            }

            let desc = MTLRenderPipelineDescriptor()
            desc.vertexFunction   = library.makeFunction(name: "aurora_vert")
            desc.fragmentFunction = library.makeFunction(name: "aurora_frag")
            desc.colorAttachments[0].pixelFormat = .bgra8Unorm

            // Standard source-over alpha blending so the aurora composites
            // over the black notch pill without covering it opaquely.
            let att = desc.colorAttachments[0]!
            att.isBlendingEnabled         = true
            att.sourceRGBBlendFactor      = .sourceAlpha
            att.destinationRGBBlendFactor = .oneMinusSourceAlpha
            att.sourceAlphaBlendFactor    = .one
            att.destinationAlphaBlendFactor = .oneMinusSourceAlpha

            commandQueue  = device.makeCommandQueue()
            pipelineState = try? device.makeRenderPipelineState(descriptor: desc)
        }

        // MARK: MTKViewDelegate

        func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}

        func draw(in view: MTKView) {
            guard let pipeline = pipelineState,
                  let queue    = commandQueue,
                  let drawable = view.currentDrawable,
                  let passDesc = view.currentRenderPassDescriptor
            else { return }

            var uniforms = AuroraUniforms(
                time:      Float(Date().timeIntervalSince(startTime)),
                intensity: intensity
            )

            guard let cmd = queue.makeCommandBuffer(),
                  let enc = cmd.makeRenderCommandEncoder(descriptor: passDesc)
            else { return }

            enc.setRenderPipelineState(pipeline)
            enc.setFragmentBytes(
                &uniforms,
                length: MemoryLayout<AuroraUniforms>.stride,
                index: 0
            )
            // 3 vertices → single fullscreen triangle (no vertex buffer needed).
            enc.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3)
            enc.endEncoding()

            cmd.present(drawable)
            cmd.commit()
        }
    }
}

// MARK: - AuroraBackground

/// Drop-in background helper: renders the Metal aurora when available,
/// falls back to plain black otherwise.
struct AuroraBackground: View {

    let intensity: Float
    private static let metalAvailable = MTLCreateSystemDefaultDevice() != nil

    var body: some View {
        if Self.metalAvailable {
            MetalView(intensity: intensity)
        } else {
            Color.black
        }
    }
}
