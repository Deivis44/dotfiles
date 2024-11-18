
# Dotfiles

## Introduction

This repository is built upon the excellent work from [end-4/dots-hyprland](https://github.com/end-4/dots-hyprland), serving as a foundation for my Hyprland setup. I've added a personalized layer of customization tailored to my workflow, providing a unique look and enhanced functionality for Hyprland.

Once the base configuration is set up, I apply my additional patch of configurations, specifically optimized for machines running Arch Linux. This setup ensures a seamless and consistent environment across devices while maintaining the flexibility to adapt to personal preferences and specific hardware requirements.

## Screenshots

![Screenshot 1](./Resources/Screenshots/1_main.png)
![Screenshot 2](./Resources/Screenshots/2_windows.png)
![Screenshot 3](./Resources/Screenshots/3_editor.png)
![Screenshot 4](./Resources/Screenshots/4_music.png)
![Screenshot 5](./Resources/Screenshots/5_browser.png)
![Screenshot 6](./Resources/Screenshots/6_files.png)
![Screenshot 7](./Resources/Screenshots/7_hyprlock.png)

### Personal Setup

- **Browser**: Zen (Alpha) + Home tab extension (mtab)
- **Monospace font**: CaskaydiaCove Nerd Font Mono
- **Terminal**: Kitty
- **Editor**: Nvim Chad (+ Tmux)
- **Music**: Spotify + Spicetify personalization layer
- **Wallpaper**: [Rocket_girl](https://mega.nz/file/3lxDWIrR#Lt53rC6Y52ZjJRAejbyBqpG6eGpu577yPOfovJCAd0o)
- **My wallpaper collection**: [Wallpapers](https://mega.nz/folder/P5pygYZQ#u-x2WmRNMVpWEt8u2Xo5fQ)
- **Stickers**: [.png & .ai files](https://github.com/Deivis44/dotfiles/tree/main/Resources/Stickers)

***

## Workflow

1. Clone the repository (default: `main`)
```
git clone https://github.com/Deivis44/dotfiles.git
cd dotfiles
```

2. Switch to the device specific branch (`desktop`/`laptop`)
```
git checkout `branch`
```

> If the branch is not locally but exists on the remote:
```
git checkout -b desktop origin/desktop
```

3. Work on the specific branch
```
nvim `file` # Make changes
git add .
git commit -m “Changes specific to desktop”
git push origin desktop
```

4. Merge the changes from the specific branch into main WITHOUT changing branch
```
git fetch origin main # Make sure you have the latest changes to main
git merge desktop main # Merge desktop changes into main
git push origin main # Upload the merged changes to the remote branch main
```

> Always merge changes to main from the specific branches.

***
