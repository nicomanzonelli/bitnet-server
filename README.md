# BitNet Server

Ubuntu 24.04 image that serves Microsoft's [BitNet-b1.58-2B-4T](https://github.com/microsoft/BitNet) model with a llama.cpp server.

## Building the Image

```
docker build -t bitnet-server .
```

## Usage

To run the container with recommended arguments, use the following command:

```
docker run -rm -it -p 8080:8080 bitnet-server -np 4 --mlock
```


You can checkout the llama.cpp server help page with the following command:

```
docker run -it bitnet-server --help
```

## Known Issues

- Only supported on x86_64 architectures. We are working on a solution for ARM64.
- The image is about 4GB in size. Can we make it smaller?

## License

[See Microsoft's BitNet License](https://github.com/microsoft/BitNet/blob/main/LICENSE)
