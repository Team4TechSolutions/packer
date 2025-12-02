# Spectrum Files Directory

This directory is **optional** and can be used to pre-bundle Spectrum application files.

## Usage

If you have Spectrum files locally and want to include them in the AMI build instead of downloading during the build:

1. Place your Spectrum package here:
   ```
   spectrum/
   ├── SpectrumV5.x.x.zip
   └── README.md
   ```

2. Update `ubuntu.pkr.hcl` to use a file provisioner:
   ```hcl
   provisioner "file" {
     source      = "./files/spectrum/SpectrumV5.x.x.zip"
     destination = "/tmp/SpectrumV5.x.x.zip"
   }
   ```

3. Set `spectrum_package_path` variable:
   ```hcl
   spectrum_package_path = "/tmp/SpectrumV5.x.x.zip"
   ```

## Alternative

You can also use `spectrum_package_url` variable to download from a URL during build, which is the default approach.

## Note

If this directory is empty, the build will use the `SPECTRUM_PACKAGE_URL` or `SPECTRUM_PACKAGE_PATH` variables instead.

