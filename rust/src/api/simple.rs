use flutter_rust_bridge::frb;

// --- Imports (Android Only) ---
#[cfg(target_os = "android")]
use oboe::{
    AudioStreamBuilder, AudioStream, PerformanceMode, SharingMode,
    DataCallbackResult, AudioOutputCallback, AudioStreamAsync,
    AudioOutputStreamSafe, Mono, Stereo,
};

// --- Structures (Android Only) ---
#[cfg(target_os = "android")]
struct SineWave {
    phase: f32,
    frequency: f32,
    sample_rate: f32,
}

#[cfg(target_os = "android")]
impl SineWave {
    fn new(frequency: f32, sample_rate: f32) -> Self {
        Self { phase: 0.0, frequency, sample_rate }
    }

    fn on_audio_ready(&mut self, audio_data: &mut [f32]) {
        use std::f32::consts::PI;
        for frame in audio_data.chunks_mut(2) {
            let sample = (self.phase * 2.0 * PI).sin() * 0.5;
            frame[0] = sample;
            frame[1] = sample;
            self.phase += self.frequency / self.sample_rate;
            if self.phase > 1.0 { self.phase -= 1.0; }
        }
    }
}

#[cfg(target_os = "android")]
struct MyCallback {
    generator: SineWave,
}

#[cfg(target_os = "android")]
impl AudioOutputCallback for MyCallback {
    // Explicitly define that we are working with Stereo (2 channels)
    type FrameType = (f32, f32);

    fn on_audio_ready(&mut self, _stream: &mut dyn AudioOutputStreamSafe, frames: &mut [f32]) -> DataCallbackResult {
        self.generator.on_audio_ready(frames);
        DataCallbackResult::Continue
    }
}

// Global variable to hold the stream (Android Only)
#[cfg(target_os = "android")]
static STREAM_HOLDER: std::sync::Mutex<Option<AudioStreamAsync<Stereo, MyCallback>>> = std::sync::Mutex::new(None);


// --- Public Functions (Visible to Dart) ---

#[frb(sync)]
pub fn start_sine_wave() -> String {
    #[cfg(target_os = "android")]
    {
        // Log initialization
        let _ = android_logger::init_once(android_logger::Config::default().with_min_level(log::Level::Info));

        let sample_rate = 48000.0;
        let callback = MyCallback { generator: SineWave::new(440.0, sample_rate) };

        // Build the stream with strict types
        let stream_result = AudioStreamBuilder::default()
            .set_performance_mode(PerformanceMode::LowLatency)
            .set_sharing_mode(SharingMode::Shared)
            .set_format::<f32>() // Explicitly set format to Float (f32)
            .set_channel_count::<Stereo>() // Explicitly set to Stereo
            .set_sample_rate(sample_rate as i32)
            .set_callback(callback)
            .open_stream();

        match stream_result {
            Ok(stream) => {
                if let Ok(_) = stream.start() {
                    let mut holder = STREAM_HOLDER.lock().unwrap();
                    *holder = Some(stream);
                    return "Audio Started! (440Hz)".to_string();
                } else {
                    return "Failed to start stream".to_string();
                }
            },
            Err(e) => return format!("Error opening stream: {:?}", e),
        }
    }

    #[cfg(not(target_os = "android"))]
    {
        return "Windows Simulation: Audio Started".to_string();
    }
}

#[frb(sync)]
pub fn stop_audio() -> String {
    #[cfg(target_os = "android")]
    {
        let mut holder = STREAM_HOLDER.lock().unwrap();
        if let Some(stream) = holder.take() {
            // Drop stream stops it automatically
            return "Audio Stopped".to_string();
        } else {
            return "Nothing to stop".to_string();
        }
    }

    #[cfg(not(target_os = "android"))]
    {
        return "Windows Simulation: Audio Stopped".to_string();
    }
}