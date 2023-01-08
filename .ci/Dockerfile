FROM nixos/nix

ENV CACHIX_NAME scottbot95-homelab

ENV NIX_CONFIG "extra-experimental-features = nix-command flakes \n\
    max-jobs = 4 \n\
    cores = 4"

RUN nix-channel --update && \
    nix-env -iA nixpkgs.cachix nixpkgs.bash

RUN cachix use ${CACHIX_NAME}

ENTRYPOINT [ "cachix", "watch-exec", "${CACHIX_NAME}" ]