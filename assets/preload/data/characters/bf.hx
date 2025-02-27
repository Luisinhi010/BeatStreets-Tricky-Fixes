function onPlayAnim(char:Character, AnimName:String) {
    if (endsWith(AnimName, 'miss'))
        char.color = 0xFF00FFFF;
    else 
        char.color = 0xFFFFFFFF;
}