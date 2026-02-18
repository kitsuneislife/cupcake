{ config, pkgs, ... }:

let
  c1 = "#ff63c1";
  c2 = "#fe369e";
  c3 = "#ff0084";
  c4 = "#ea3785";
in
{
  # Home-module: home/programs/shell.nix
  # Purpose: Shell settings and aliases (moved from `home.nix`).

  programs.bash = {
    enable = true;
    shellAliases = {
      ll = "ls -la";
      nixup = "sudo nixos-rebuild switch";
    };
  };

  programs.starship = {
    enable = true;
    enableBashIntegration = true;
    settings = {

      format = pkgs.lib.concatStrings [
        "[░▒▓](${c1})"
        "$os"
        "$username"
        "[](bg:${c2} fg:${c1})"
        "$directory"
        "[](fg:${c2} bg:${c3})"
        "$git_branch"
        "$git_status"
        "[](fg:${c3} bg:${c4})"
        "$c"
        "$elixir"
        "$elm"
        "$golang"
        "$gradle"
        "$haskell"
        "$java"
        "$julia"
        "$nodejs"
        "$nim"
        "$rust"
        "$scala"
        "$docker_context"
        "[](fg:${c4} bg:${c1})"
        "$time"
        "[ ](fg:${c1})"
      ];

      # ── 4-color palette ───────────────────────────────────────────────
      # c1 #c084fc  roxo
      # c2 #f472b6  rosa
      # c3 #fb923c  laranja
      # c4 #e879f9  fucsia
      # ─────────────────────────────────────────────────────────────────

      username = {
        show_always  = true;
        style_user   = "bg:${c1}";
        style_root   = "bg:${c1}";
        format       = "[ $user ]($style)";
        disabled     = false;
      };

      os = {
        style    = "bg:${c1}";
        disabled = true;
      };

      directory = {
        style             = "bg:${c2}";
        format            = "[ $path ]($style)";
        truncation_length = 3;
        truncation_symbol = "…/";
        substitutions = {
          "Documents" = "󰈙 ";
          "Downloads" = " ";
          "Music"     = " ";
          "Pictures"  = " ";
        };
      };

      git_branch = {
        symbol = "";
        style  = "bg:${c3}";
        format = "[ $symbol $branch ]($style)";
      };

      git_status = {
        style  = "bg:${c3}";
        format = "[$all_status$ahead_behind ]($style)";
      };

      c = {
        symbol = " ";
        style  = "bg:${c4}";
        format = "[ $symbol ($version) ]($style)";
      };

      elixir = {
        symbol = " ";
        style  = "bg:${c4}";
        format = "[ $symbol ($version) ]($style)";
      };

      elm = {
        symbol = " ";
        style  = "bg:${c4}";
        format = "[ $symbol ($version) ]($style)";
      };

      golang = {
        symbol = " ";
        style  = "bg:${c4}";
        format = "[ $symbol ($version) ]($style)";
      };

      gradle = {
        style  = "bg:${c4}";
        format = "[ $symbol ($version) ]($style)";
      };

      haskell = {
        symbol = " ";
        style  = "bg:${c4}";
        format = "[ $symbol ($version) ]($style)";
      };

      java = {
        symbol = " ";
        style  = "bg:${c4}";
        format = "[ $symbol ($version) ]($style)";
      };

      julia = {
        symbol = " ";
        style  = "bg:${c4}";
        format = "[ $symbol ($version) ]($style)";
      };

      nodejs = {
        symbol = "";
        style  = "bg:${c4}";
        format = "[ $symbol ($version) ]($style)";
      };

      nim = {
        symbol = "󰆥 ";
        style  = "bg:${c4}";
        format = "[ $symbol ($version) ]($style)";
      };

      rust = {
        symbol = "";
        style  = "bg:${c4}";
        format = "[ $symbol ($version) ]($style)";
      };

      scala = {
        symbol = " ";
        style  = "bg:${c4}";
        format = "[ $symbol ($version) ]($style)";
      };

      docker_context = {
        symbol = " ";
        style  = "bg:${c4}";
        format = "[ $symbol $context ]($style)";
      };

      time = {
        disabled    = false;
        time_format = "%R";
        style       = "bg:${c1}";
        format      = "[ ♥ $time ]($style)";
      };
    };
  };
}
