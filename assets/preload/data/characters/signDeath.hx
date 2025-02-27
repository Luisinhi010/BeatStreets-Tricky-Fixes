function onCreateAfter(char:Character) {
	char.playAnim('firstDeath');
	char.updateHitbox();
}