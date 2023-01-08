FROM nixos/nix

ENV CACHIX_NAME scottbot95-homelab

RUN nix-channel --update && \
    nix-env -iA nixpkgs.cachix nixpkgs.bash

RUN cachix use ${CACHIX_NAME}

ENTRYPOINT [ "cachix", "watch-exec", "${CACHIX_NAME}" ]