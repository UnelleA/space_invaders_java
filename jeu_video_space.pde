import processing.sound.*;

// Variables globales
PImage vaisseauImage, ennemiImage, projectileImage, projectileEnnemiImage, bonusImage, bonusVieImage;
Vaisseau joueur;
Vaisseau joueur2;
ArrayList<Integer> meilleursScores = new ArrayList<Integer>();

ArrayList<Projectile> projectiles = new ArrayList<>();
ArrayList<Ennemi> ennemis = new ArrayList<>();
ArrayList<ProjectileEnnemi> projectilesEnnemis = new ArrayList<>();
ArrayList<Bonus> bonusList = new ArrayList<>();

int viesJoueur1 = 3;
int viesJoueur2 = 3;
boolean joueur2Actif = false; // Nouvelle variable pour activer ou désactiver le joueur 2

int cooldown = 300;
int lastShotTime = 0;
boolean ennemisVersDroite = true;
float vitesseEnnemis = 1;
int score = 0;
int cooldownTirEnnemi = 1000;
int dernierTirEnnemi = 0;
int vies = 3;
int niveau = 1;
float probabilitéTirEnnemi = 0.01;
int lignesEnnemisInitial = 3;
boolean niveauEnCours = true;

int intervalleBonus = 10000;
int dernierBonus = 0;

// Sons
SoundFile hitSound;
SoundFile tirSound;
SoundFile explosionSound;
SoundFile backgroundMusic;

// État du jeu
enum GameState {
    MENU, JEU, PAUSE, GAME_OVER
}
GameState gameState = GameState.MENU;

void setup() {
    size(800, 600);

    // Chargement des images des sprites
    vaisseauImage = loadImage("vaisseau.png");
    vaisseauImage.resize(40, 30);
    ennemiImage = loadImage("ennemi.png");
    ennemiImage.resize(30, 30);
    projectileImage = loadImage("projectile.png");
    projectileImage.resize(20, 30);
    projectileEnnemiImage = loadImage("projectileEnnemi.png");
    projectileEnnemiImage.resize(10, 20);
    bonusImage = loadImage("bonus.png");
    bonusImage.resize(20, 20);
    bonusVieImage = loadImage("bonusVie.png");
    bonusVieImage.resize(20, 20);

    joueur = new Vaisseau(width / 4, height - 50); // Position initiale joueur 1
    joueur2 = new Vaisseau(3 * width / 4, height - 50); // Position initiale joueur 2

    // Chargement des fichiers audio
    hitSound = new SoundFile(this, "hitSound.mp3");
    tirSound = new SoundFile(this, "tirSound.mp3");
    explosionSound = new SoundFile(this, "explosionSound.mp3");
    backgroundMusic = new SoundFile(this, "backgroundMusic.mp3");

    // Lancer la musique de fond en boucle
    backgroundMusic.loop();
}

void draw() {
    switch (gameState) {
        case MENU:
            displayMenu();
            break;
        case JEU:
            playGame();
            break;
        case PAUSE:
            displayPauseScreen();
            break;
        case GAME_OVER:
            displayGameOver();
            break;
    }
}

void displayMenu() {
    background(0);
    textSize(32);
    fill(255);
    textAlign(CENTER);
    text("Space Invaders", width / 2, height / 2 - 40);
    textSize(20);
    text("Appuyez sur 'N' pour commencer une nouvelle partie", width / 2, height / 2);
    text("Appuyez sur 'P' pour mettre pause ou play", width / 2, height / 2 + 30);
    

    // Affichage du tableau des meilleurs scores
    textSize(16);
    textAlign(LEFT);
    text("Meilleurs Scores :", 20, height / 2 + 80);
    for (int i = 0; i < meilleursScores.size(); i++) {
        text("Score " + (i + 1) + ": " + meilleursScores.get(i), 10, 20 + i * 20);
    }
}

void displayPauseScreen() {
    background(0, 150);
    textSize(32);
    fill(255);
    textAlign(CENTER);
    text("Pause", width / 2, height / 2);
    textSize(20);
    text("Appuyez sur 'P' pour reprendre", width / 2, height / 2 + 30);
}

void displayGameOver() {
    background(0);
    textSize(32);
    fill(255);
    textAlign(CENTER);
    text("Game Over", width / 2, height / 2 - 40);
    textSize(20);
    text("Score final: " + score, width / 2, height / 2);
    text("Appuyez sur 'N' pour une nouvelle partie", width / 2, height / 2 + 30);

    // Ajouter le score actuel au tableau des meilleurs scores
    ajouterScore(score);
}

// Fonction pour ajouter un score et trier le tableau manuellement
void ajouterScore(int nouveauScore) {
    meilleursScores.add(nouveauScore);
    // Tri manuel de la liste des scores en ordre décroissant
    for (int i = 0; i < meilleursScores.size(); i++) {
        for (int j = i + 1; j < meilleursScores.size(); j++) {
            if (meilleursScores.get(j) > meilleursScores.get(i)) {
                int temp = meilleursScores.get(i);
                meilleursScores.set(i, meilleursScores.get(j));
                meilleursScores.set(j, temp);
            }
        }
    }
    
    // Limiter le tableau des meilleurs scores à 5 entrées
    if (meilleursScores.size() > 5) {
        meilleursScores.remove(meilleursScores.size() - 1);
    }
}

// Appel de la fonction pour tester
void mousePressed() {
    int nouveauScore = int(random(100)); // Génère un score aléatoire pour le test
    ajouterScore(nouveauScore);
}

void playGame() {
    background(150);
    
    joueur.update();
    joueur.display();

    if (joueur2Actif) { // Affichage du joueur 2 si activé
        joueur2.update();
        joueur2.display();
    }

    updateProjectiles();
    for (int i = projectilesEnnemis.size() - 1; i >= 0; i--) {
    ProjectileEnnemi pE = projectilesEnnemis.get(i);
    pE.update();
    pE.display();

    if (pE.checkCollision(joueur)) {
        if (!joueur.bouclier) {
            hitSound.play();
            viesJoueur1--; // Diminue les vies du joueur 1
            if (viesJoueur1 <= 0) {
                gameState = GameState.GAME_OVER;
            }
        }
        projectilesEnnemis.remove(i);
    } else if (joueur2Actif && pE.checkCollision(joueur2)) {
        if (!joueur2.bouclier) {
            hitSound.play();
            viesJoueur2--; // Diminue les vies du joueur 2
            if (viesJoueur2 <= 0) {
                joueur2Actif = false; // Désactive le joueur 2 si ses vies tombent à 0
                println("Joueur 2 est éliminé !");
            }
        }
        projectilesEnnemis.remove(i);
    }

    if (pE.isOffScreen()) {
        projectilesEnnemis.remove(i);
    }
}

    updateEnnemis();

    // Affichage du score, des vies et du niveau actuel
    fill(255);
    textSize(20);
    text("Score: " + score, 10, 20);
    text("Vies Joueur 1: " + viesJoueur1, width - 325, 20);
    if (joueur2Actif) { // Affiche les vies du joueur 2 seulement s'il est actif
        text("Vies Joueur 2: " + viesJoueur2, width - 150, 20);
    }
    text("Niveau: " + niveau, width - 500, 20);
    text("Appuyez sur 'M' pour activer ou desactiver le mode Multijoueur", width - 590, 50, 5);

    // Apparition de bonus à intervalles réguliers
    if (millis() - dernierBonus > intervalleBonus) {
        genererBonus();
        dernierBonus = millis();
    }

    // Mise à jour et affichage des bonus
    updateBonus();

    // Passage au niveau suivant si tous les ennemis sont éliminés
    if (ennemis.isEmpty() && niveauEnCours) {
        niveauEnCours = false;
        niveauSuivant();
    }
}

void niveauSuivant() {
    niveau++;
    vitesseEnnemis += 0.5;
    probabilitéTirEnnemi += 0.005;
    lignesEnnemisInitial += 1;
    genererEnnemis();
    niveauEnCours = true;
}

void genererEnnemis() {
    ennemis.clear();
    int colonnes = int(random(5, 10));
    int lignes = int(random(2, lignesEnnemisInitial + 1));
    float espacementX = 50;
    float espacementY = 40;
    float offsetX = 100;
    float offsetY = 50;

    for (int i = 0; i < lignes; i++) {
        for (int j = 0; j < colonnes; j++) {
            float x = offsetX + j * espacementX + random(-10, 10);
            float y = offsetY + i * espacementY;
            float taille = random(20, 40);
            float vitesseY = random(0.5, 2.5);
            int typeComportement = int(random(3));
            ennemis.add(new Ennemi(x, y, taille, vitesseY, typeComportement));
        }
    }
}

void updateEnnemis() {
    boolean changerDirection = false;
    for (Ennemi ennemi : ennemis) {
        if ((ennemisVersDroite && ennemi.x + ennemi.taille / 2 >= width) || (!ennemisVersDroite && ennemi.x - ennemi.taille / 2 <= 0)) {
            changerDirection = true;
            break;
        }
    }
    if (changerDirection) {
        ennemisVersDroite = !ennemisVersDroite;
        for (Ennemi ennemi : ennemis) {
            ennemi.descendre();
        }
    }
    float dx = ennemisVersDroite ? vitesseEnnemis : -vitesseEnnemis;
    for (Ennemi ennemi : ennemis) {
        ennemi.update(dx);
        int currentTime = millis();
        if (currentTime - dernierTirEnnemi > cooldownTirEnnemi && random(1) < probabilitéTirEnnemi) {
            ennemi.tirer();
            dernierTirEnnemi = currentTime;
        }
        ennemi.display();
    }
}

void updateProjectiles() {
    for (int i = projectiles.size() - 1; i >= 0; i--) {
        Projectile p = projectiles.get(i);
        p.update();
        p.display();

        for (int j = ennemis.size() - 1; j >= 0; j--) {
            Ennemi ennemi = ennemis.get(j);
            if (p.checkCollision(ennemi)) {
                projectiles.remove(i);
                ennemis.remove(j);
                explosionSound.play();
                score += 100;
                break;
            }
        }

        if (p.isOffScreen()) {
            projectiles.remove(i);
        }
    }

    for (int i = projectilesEnnemis.size() - 1; i >= 0; i--) {
        ProjectileEnnemi pE = projectilesEnnemis.get(i);
        pE.update();
        pE.display();

        if (pE.checkCollision(joueur)) {
            if (!joueur.bouclier) {
                hitSound.play();
                vies--;
                if (vies <= 0) {
                    println("Game Over! Final Score: " + score);
                    noLoop();
                }
            }
            projectilesEnnemis.remove(i);
        }

        if (pE.isOffScreen()) {
            projectilesEnnemis.remove(i);
        }
    }
}

void updateBonus() {
    for (int i = bonusList.size() - 1; i >= 0; i--) {
        Bonus bonus = bonusList.get(i);
        bonus.update();
        bonus.display();

        // Vérification des collisions de chaque bonus avec les deux joueurs
        if (bonus.checkCollision(joueur)) {
            bonus.appliquerEffet(joueur, "Joueur 1");
            bonusList.remove(i);
        } else if (bonus.checkCollision(joueur2)) {
            bonus.appliquerEffet(joueur2, "Joueur 2");
            bonusList.remove(i);
        }
        
        if (bonus.isOffScreen()) {
            bonusList.remove(i);
        }
    }
}

void genererBonus() {
    float x = random(50, width - 50);
    if (random(1) < 0.3) {
        bonusList.add(new Bonus(x, 0, true));
    } else {
        bonusList.add(new Bonus(x, 0, false));
    }
}

void keyPressed() {
  if (gameState == GameState.MENU && (key == 'N' || key == 'n')) {
        gameState = GameState.JEU;
        resetGame();
    } else if (gameState == GameState.JEU && (key == 'P' || key == 'p')) {
        gameState = GameState.PAUSE;
    } else if (gameState == GameState.PAUSE && (key == 'P' || key == 'p')) {
        gameState = GameState.JEU;
    } else if (gameState == GameState.GAME_OVER && (key == 'N' || key == 'n')) {
        gameState = GameState.JEU;
        resetGame();
    }
    if (gameState == GameState.JEU) {
        if (key == 'M' || key == 'm') { // Touche pour activer/désactiver le joueur 2
            joueur2Actif = !joueur2Actif;
        }
        // Contrôles du joueur 1
        if (keyCode == LEFT) {
            joueur.setDirection(-1);
        } else if (keyCode == RIGHT) {
            joueur.setDirection(1);
        } else if (key == ' ') {
            int currentTime = millis();
            if (currentTime - lastShotTime > joueur.cadenceTir) {
                if (joueur.tirsMultiples) {
                    projectiles.add(new Projectile(joueur.x - 10, joueur.y - joueur.hauteur / 2));
                    projectiles.add(new Projectile(joueur.x + 10, joueur.y - joueur.hauteur / 2));
                } else {
                    projectiles.add(new Projectile(joueur.x, joueur.y - joueur.hauteur / 2));
                }
                tirSound.play();
                lastShotTime = currentTime;
            }
        }
        
        // Contrôles du joueur 2
        if (joueur2Actif) { // Activation des contrôles du joueur 2 seulement s'il est actif
            if (key == 'A' || key == 'a') {
                joueur2.setDirection(-1);
            } else if (key == 'D' || key == 'd') {
                joueur2.setDirection(1);
            } else if (key == 'Q' || key == 'q') {
                int currentTime = millis();
                if (currentTime - lastShotTime > joueur2.cadenceTir) {
                    if (joueur2.tirsMultiples) {
                        projectiles.add(new Projectile(joueur2.x - 10, joueur2.y - joueur2.hauteur / 2));
                        projectiles.add(new Projectile(joueur2.x + 10, joueur2.y - joueur2.hauteur / 2));
                    } else {
                        projectiles.add(new Projectile(joueur2.x, joueur2.y - joueur2.hauteur / 2));
                    }
                    tirSound.play();
                    lastShotTime = currentTime;
                }
            }
        }
    }
}

void keyReleased() {
    if (keyCode == LEFT || keyCode == RIGHT) {
        joueur.setDirection(0);
    }
    if (joueur2Actif && (key == 'A' || key == 'D' || key == 'a' || key == 'd')) {
        joueur2.setDirection(0);
    }
}

void resetGame() {
    vies = 3;
    score = 0;
    niveau = 1;
    vitesseEnnemis = 1;
    probabilitéTirEnnemi = 0.01;
    lignesEnnemisInitial = 3;
    projectiles.clear();
    ennemis.clear();
    projectilesEnnemis.clear();
    bonusList.clear();
    joueur = new Vaisseau(width / 4, height - 50);
    joueur2 = new Vaisseau(3 * width / 4, height - 50);
    genererEnnemis();
}

// Classe Ennemi
class Ennemi {
    float x, y;
    float taille;
    float vitesseY;
    int typeComportement;

    Ennemi(float x, float y, float taille, float vitesseY, int typeComportement) {
        this.x = x;
        this.y = y;
        this.taille = taille;
        this.vitesseY = vitesseY;
        this.typeComportement = typeComportement;
    }

    void update(float dx) {
        x += dx;

        if (typeComportement == 1) {
            y += sin(frameCount * 0.1) * vitesseY;
        } else if (typeComportement == 2) {
            x += sin(frameCount * 0.1) * 2;
        }
    }

    void display() {
        image(ennemiImage, x - taille / 2, y - taille / 2);
    }

    void descendre() {
        y += taille / 2;
    }

    void tirer() {
        projectilesEnnemis.add(new ProjectileEnnemi(x, y + taille / 2));
    }
}

// Classe Projectile
class Projectile {
    float x, y;
    float vitesseY = -5;

    Projectile(float x, float y) {
        this.x = x;
        this.y = y;
    }

    void update() {
        y += vitesseY;
    }

    void display() {
        image(projectileImage, x - 10, y - 10);
    }

    boolean isOffScreen() {
        return y < 0;
    }

    boolean checkCollision(Ennemi ennemi) {
        float distance = dist(x, y, ennemi.x, ennemi.y);
        return distance < (10 + ennemi.taille / 2);
    }
}

// Classe ProjectileEnnemi
class ProjectileEnnemi {
    float x, y;
    float vitesseY = 5;

    ProjectileEnnemi(float x, float y) {
        this.x = x;
        this.y = y;
    }

    void update() {
        y += vitesseY;
    }

    void display() {
        image(projectileEnnemiImage, x - 5, y - 10);
    }

    boolean isOffScreen() {
        return y > height;
    }

    boolean checkCollision(Vaisseau vaisseau) {
        float distance = dist(x, y, vaisseau.x, vaisseau.y);
        return distance < (5 + vaisseau.largeur / 2);
    }
}

// Classe Bonus
class Bonus {
    float x, y;
    float vitesseY = 2;
    int type; // 0: tirs multiples, 1: bouclier, 2: vitesse de tir
    boolean estBonusVie;

    Bonus(float x, float y, boolean estBonusVie) {
        this.x = x;
        this.y = y;
        this.estBonusVie = estBonusVie;
        
        if (!estBonusVie) {
            this.type = int(random(3)); // Choisit un type pour les autres bonus aléatoirement
        }
    }

    void update() {
        y += vitesseY;
    }

    void display() {
        if (estBonusVie) {
            image(bonusVieImage, x - 10, y - 10); // Utilise l'image de bonus de vie
        } else {
            image(bonusImage, x - 10, y - 10); // Utilise l'image des autres bonus
        }
    }

    boolean isOffScreen() {
        return y > height;
    }

    boolean checkCollision(Vaisseau vaisseau) {
        float distance = dist(x, y, vaisseau.x, vaisseau.y);
        return distance < (10 + vaisseau.largeur / 2);
    }

    void appliquerEffet(Vaisseau vaisseau, String joueur) {
        if (estBonusVie) {
            println(joueur + " - Vie ajoutée !");
            if (joueur.equals("Joueur 1")) {
                viesJoueur1++; // Augmente les vies du joueur 1
            } else {
                viesJoueur2++; // Augmente les vies du joueur 2
            }
        } else {
            if (type == 0) {
                println(joueur + " - Tirs multiples activés !");
                vaisseau.activerTirsMultiples();
            } else if (type == 1) {
                println(joueur + " - Bouclier activé !");
                vaisseau.activerBouclier();
            } else if (type == 2) {
                println(joueur + " - Vitesse de tir augmentée !");
                vaisseau.augmenterCadenceTir();
            }
        }
    }
}

class Vaisseau {
    float x, y;
    int largeur = 40;
    int hauteur = 30;
    int direction = 0;
    float vitesse = 5;
    boolean tirsMultiples = false;
    boolean bouclier = false;
    int cadenceTir = 300;

    int tirMultipleTime = 0;
    int bouclierTime = 0;
    int cadenceTirTime = 0;
    int bonusDuration = 5000; // Durée en millisecondes (5 secondes)

    Vaisseau(float x, float y) {
        this.x = x;
        this.y = y;
    }

    void update() {
    x += direction * vitesse;
    x = constrain(x, largeur / 2, width - largeur / 2);

    // Mise à jour des bonus temporisés
    if (tirsMultiples && millis() - tirMultipleTime > bonusDuration) {
        tirsMultiples = false; // Désactivation après la durée spécifiée
    }
    if (bouclier && millis() - bouclierTime > bonusDuration) {
        bouclier = false;
    }
    if (cadenceTir == 100 && millis() - cadenceTirTime > bonusDuration) {
        cadenceTir = 300; // Rétablissement de la cadence normale
    }
}


    void display() {
        // Change l'apparence du vaisseau selon les bonus actifs
        if (bouclier) {
            stroke(0, 0, 255); // Affiche un contour bleu pour le bouclier
            strokeWeight(3);
        } else {
            noStroke();
        }
        image(vaisseauImage, x - largeur / 2, y - hauteur / 2);

        // Affichage du statut des bonus au-dessus du vaisseau
        fill(255);
        textSize(12);
        if (tirsMultiples) text("Tir multiple", x - 20, y - hauteur / 2 - 20);
        if (bouclier) text("Bouclier", x - 20, y - hauteur / 2 - 10);
        if (cadenceTir == 100) text("Cadence++", x - 20, y - hauteur / 2 - 30);
    }

    void setDirection(int dir) {
        direction = dir;
    }

    void activerTirsMultiples() {
        tirsMultiples = true;
        tirMultipleTime = millis(); // Enregistre l'heure d'activation
    }

    void activerBouclier() {
        bouclier = true;
        bouclierTime = millis();
    }

    void augmenterCadenceTir() {
        cadenceTir = 100;
        cadenceTirTime = millis();
    }
}
