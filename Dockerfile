FROM nixos/nix:latest

# Enable flakes and KVM
RUN echo "experimental-features = nix-command flakes" >> /etc/nix/nix.conf && \
    echo "system-features = nixos-test benchmark big-parallel kvm" >> /etc/nix/nix.conf

WORKDIR /app

COPY build-vma.sh /usr/local/bin/build-vma
RUN chmod +x /usr/local/bin/build-vma

ENTRYPOINT ["/usr/local/bin/build-vma"]
