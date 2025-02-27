package;

#if linux
@:headerCode('
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <unistd.h>
#include <X11/Xlib.h>
')

class LinuxAPI {
    // Steam Deck detection
    @:functionCode('
        FILE *fp;
        char path[1035];
        bool is_deck = false;

        // Executar o comando para verificar o sistema
        fp = popen("cat /etc/os-release | grep -i \"steam\"", "r");
        if (fp == NULL) {
            return false;
        }

        // Verificar a saída
        while (fgets(path, sizeof(path), fp) != NULL) {
            if (strstr(path, "steamos") != NULL) {
                is_deck = true;
                break;
            }
        }

        pclose(fp);
        return is_deck;
    ')
    public static function isSteamDeck():Bool { return false; }
    
    // Gamemode integration (Feral Interactive)
    @:functionCode('
        // Verifica se o gamemode está instalado
        FILE *fp = popen("which gamemoderun", "r");
        if (fp == NULL) {
            return false;
        }
        
        char path[1035];
        bool has_gamemode = fgets(path, sizeof(path), fp) != NULL;
        pclose(fp);
        
        if (!has_gamemode) {
            return false;
        }
        
        // Tenta ativar o gamemode via variável de ambiente
        putenv("LD_PRELOAD=/usr/lib/libgamemode.so");
        
        return true;
    ')
    public static function requestGameMode():Bool { return false; }
    
    // Compositor control
    @:functionCode('
        // Desativar KDE compositor
        FILE *fp = popen("qdbus org.kde.KWin /Compositor suspend", "r");
        if (fp != NULL) {
            pclose(fp);
            return true;
        }
        
        // Tentar desativar Mutter/GNOME compositor
        fp = popen("gsettings set org.gnome.mutter experimental-features \"[\\'disable-compositor\\']\"", "r");
        if (fp != NULL) {
            pclose(fp);
            return true;
        }
        
        return false;
    ')
    public static function disableCompositor():Bool { return false; }
    
    @:functionCode('
        // Restaurar KDE compositor
        FILE *fp = popen("qdbus org.kde.KWin /Compositor resume", "r");
        if (fp != NULL) {
            pclose(fp);
        }
        
        // Restaurar GNOME compositor
        fp = popen("gsettings reset org.gnome.mutter experimental-features", "r");
        if (fp != NULL) {
            pclose(fp);
        }
    ')
    public static function restoreCompositor():Void {}
    
    // Desktop notifications
    @:functionCode('
        char command[1024];
        sprintf(command, "notify-send \"%s\" \"%s\"", title, body);
        system(command);
    ')
    public static function showDesktopNotification(title:String, body:String):Void {}
    
    // Driver optimization
    @:functionCode('
        FILE *fp;
        char path[1035];
        char driver[256] = "unknown";

        // Tenta detectar driver gráfico
        fp = popen("glxinfo | grep \"OpenGL vendor\"", "r");
        if (fp != NULL) {
            if (fgets(path, sizeof(path), fp) != NULL) {
                if (strstr(path, "NVIDIA") != NULL) {
                    strcpy(driver, "nvidia");
                } else if (strstr(path, "AMD") != NULL || strstr(path, "ATI") != NULL) {
                    strcpy(driver, "amd");
                } else if (strstr(path, "Intel") != NULL) {
                    strcpy(driver, "intel");
                }
            }
            pclose(fp);
        }

        return driver;
    ')
    public static function getGraphicsDriver():String { return "unknown"; }
    
    @:functionCode('
        // Detecta o driver e aplica otimizações específicas
        char driver[256] = "unknown";
        FILE *fp = popen("glxinfo | grep \"OpenGL vendor\"", "r");
        if (fp != NULL) {
            char path[1035];
            if (fgets(path, sizeof(path), fp) != NULL) {
                if (strstr(path, "NVIDIA") != NULL) {
                    // Otimizações para NVIDIA
                    putenv("__GL_THREADED_OPTIMIZATIONS=1");
                } else if (strstr(path, "AMD") != NULL || strstr(path, "ATI") != NULL) {
                    // Otimizações para AMD
                    putenv("mesa_glthread=true");
                }
            }
            pclose(fp);
        }
    ')
    public static function optimizeForDriver():Void {}
}
#end
