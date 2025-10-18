use bmp390::Bmp390;
use embedded_hal_async::delay::DelayNs;
use linux_embedded_hal::I2cdev;

// The I2C device path for the Raspberry Pi.
const I2C_DEVICE: &str = "/dev/i2c-1";

struct TokioDelay;

impl DelayNs for TokioDelay {
    async fn delay_ns(&mut self, ns: u32) {
        tokio::time::sleep(tokio::time::Duration::from_nanos(ns as u64)).await;
    }
}

#[tokio::main]
pub async fn main() {
    let config = bmp390::Configuration::default();
    let i2c = I2cdev::new(I2C_DEVICE).expect("Failed to create I2C device");
    let mut sensor = Bmp390::try_new(i2c, bmp390::Address::Up, TokioDelay, &config)
        .await
        .expect("Failed to create BMP390 sensor");
    let measurement = sensor.measure().await.expect("Failed to get measurement");
    println!("Measurement: {}", measurement);
}
