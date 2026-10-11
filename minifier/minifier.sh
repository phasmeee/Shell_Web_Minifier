#!/bin/dash

# ==============================================================================
# Nom : Julien Bouveret
# 
# Conclusion / Bilan :
# - Fait et testé : Minification complète du HTML (suppression commentaires et 
#   espaces) et du CSS. La structure de l'arborescence est scrupuleusement 
#   recréée. Les options --help, -v (pourcentage), -f (écrasement forcé) et -t 
#   (fichier tags) sont totalement fonctionnelles et respectent les 
#   spécifications. Le traitement des balises (-t) est insensible à la casse.
# - Non fait : /
# - Le script est 100% compatible avec l'interpréteur POSIX dash.
# ==============================================================================

#    ______   __  __     __   __     ______     ______   __     ______     __   __     ______    
#   /\  ___\ /\ \/\ \   /\ "-.\ \   /\  ___\   /\__  _\ /\ \   /\  __ \   /\ "-.\ \   /\  ___\   
#   \ \  __\ \ \ \_\ \  \ \ \-.  \  \ \ \____  \/_/\ \/ \ \ \  \ \ \/\ \  \ \ \-.  \  \ \___  \  
#    \ \_\    \ \_____\  \ \_\\"\_\  \ \_____\    \ \_\  \ \_\  \ \_____\  \ \_\\"\_\  \/\_____\ 
#     \/_/     \/_____/   \/_/ \/_/   \/_____/     \/_/   \/_/   \/_____/   \/_/ \/_/   \/_____/ 
                                                                                             
# ------------------------------------------------------------------------------
# Rôle : 
#   Affiche l'aide détaillée du script sur la sortie standard.
#
# Paramètres attendus : 
#   Aucun
#
# Ce que la fonction renvoie :
#   Ne renvoie rien, se contente d'afficher du texte.
# ------------------------------------------------------------------------------
help()
{
    echo "usage : $0 [OPTION]... DIR_SOURCE DIR_DEST"
    echo
    echo "Minifies HTML and CSS files with :"
    echo "    DIR_SOURCE   path to the root directory of the website to be minified"
    echo "    DIR_DEST     path to the root directory of the minified website"
    echo "OPTIONS"
    echo "    --help       show help and exit"
    echo "    -v           displays the list of minified files ; and for each"
    echo "                 file, its final and initial sizes, and its reduction"
    echo "                 percentage"
    echo "    -f           if the DIR_DEST file exists, its content is"
    echo "                 removed without asking for confirmation of deletion"
    echo
    echo "    -t TAGS_FILE the \"white space\" characters preceding and following the"
    echo "                 tags (opening or closing) listed in the 'TAGS_FILE' are deleted"
}

# ------------------------------------------------------------------------------
# Rôle : 
#   Calcule et affiche le pourcentage de réduction d'un fichier après 
#   minification.
#
# Paramètres attendus : 
#   $1 : Type de fichier (ex: "HTML" ou "CSS")
#   $2 : Chemin vers le fichier source initial
#   $3 : Chemin vers le fichier minifié de destination
#
# Ce que la fonction renvoie :
#   Affiche sur la sortie standard une chaîne formatée indiquant les tailles et 
#   le pourcentage de réduction.
# ------------------------------------------------------------------------------
show_reduction_percent()
{
    SIZE_INIT=$(wc -c < "$2")
    SIZE_DEST=$(wc -c < "$3")

    if test "$SIZE_INIT" -eq 0
    then
        PERCENT=0 # sécurité division par 0 EXPLOSION
    else
        PERCENT=$(( (SIZE_INIT - SIZE_DEST) * 100 / SIZE_INIT ))
    fi

    echo "File $1: $3 --> $SIZE_DEST / $SIZE_INIT: $PERCENT%"
}

# ------------------------------------------------------------------------------
# Rôle : 
#   Minifie un fichier HTML (espaces, retours à la ligne, commentaires) et gère
#   le nettoyage optionnel des balises via un fichier de tags.
#
# Paramètres attendus : 
#   $1 : Chemin vers le fichier HTML source à minifier
#   $2 : Chemin vers le fichier HTML minifié cible
#   $3 : (Optionnel) Chemin vers le fichier texte contenant les balises (TAGS_FILE)
#
# Ce que la fonction renvoie :
#   Retourne 0 en cas de succès, ou exit 1 avec une erreur en cas d'échec d'une 
#   commande.
# ------------------------------------------------------------------------------
minifie_HTML()
{
    # traitements des espaces et commentaires
    tr -s '[:space:]' ' ' < "$1" |  # squeeze des espaces blancs répétés
    sed 's/<!--/\n/g' |             # remplacement des balises ouvrantes de commentaires par des sauts de lignes
    sed 's/.*-->//' |               # si contient une balise fermantes de commentaires, supprime le début de la ligne (balise incluse)
    tr -d '\n' > "$2" || exit 1     # supprime les sauts de lignes '\n' (recolle les lignes)
    # [le même principe est appliqué dans 'minifie_CSS']

    # traitement optionnel des balises blocs (-t)
    # pourrait utiliser une variable globale, mais je préfère que la fonction
    # puisse marcher toute seul en dehors de se script à l'instar de "minifie_CSS"
    if test -n "$3"
    then
        TAGS=$(cat "$3")
        for TAG in $TAGS
        do
            # création motif anti-casse POSIX pur
            PATTERN=''
            REST=$TAG

            while test -n "$REST"
            do
                CHAR=$(printf '%s' "$REST" | cut -c1)
                REST=$(printf '%s' "$REST" | cut -c2-)

                case "$CHAR" in
                    [a-z])
                        UPPER=$(printf '%s' "$CHAR" | tr '[:lower:]' '[:upper:]')
                        PATTERN="${PATTERN}[${CHAR}${UPPER}]"
                        ;;
                    [A-Z])
                        LOWER=$(printf '%s' "$CHAR" | tr '[:upper:]' '[:lower:]')
                        PATTERN="${PATTERN}[${LOWER}${CHAR}]"
                        ;;
                    *)
                        PATTERN="${PATTERN}${CHAR}"
                        ;;
                esac
            done

            # suppression des espaces derrières les balises de TAGS_FILE
                #balises ouvrantes
                #balises avec variables
                #balises fermantes
            # '\' -> commande multiligne (plus lisible, mais on peut pas mettre de commentaire en bout (vécu))
            sed \
                -e "s/<${PATTERN}[[:space:]]*>/<${TAG}>/g" \
                -e "s/<${PATTERN}\([[:space:]][^>]*\)>/<${TAG}\1>/g" \
                -e "s/<\/${PATTERN}[[:space:]]*>/<\/${TAG}>/g" \
                "$2" > "$2.tmp" || exit 1 # fichier temporaire pour éviter de casser le fichier a cause de l'ordonnanceur 
            mv "$2.tmp" "$2" || exit 1
        done
    fi

    # suppression des espaces entre balises
    sed 's/>[[:space:]]*</></g' "$2" > "$2.tmp" || exit 1 # même principe de fichier temporaire
    mv "$2.tmp" "$2" || exit 1
}

# ------------------------------------------------------------------------------
# Rôle : 
#   Minifie un fichier CSS (espaces, commentaires, formatage).
#
# Paramètres attendus : 
#   $1 : Chemin vers le fichier CSS source à minifier
#   $2 : Chemin vers le fichier CSS minifié cible
#
# Ce que la fonction renvoie :
#   Retourne 0 en cas de succès, ou exit 1 en cas d'échec.
# ------------------------------------------------------------------------------
minifie_CSS()
{
    # traitements des espaces et commentaires
    tr -s '[:space:]' ' ' < "$1" |  # squeeze des espaces blancs répétés
    sed 's/\/\*/\n/g' |             # remplacement des balises ouvrantes de commentaires par des sauts de lignes
    sed 's/.*\*\///' |              # si contient une balise fermantes de commentaires, supprime le début de la ligne (balise incluse)
    tr -d '\n' |                    # supprime les sauts de lignes '\n' (recolle les lignes)
    ## [le même principe est appliqué dans 'minifie_HTML']
    # supprime les espaces non essentielles propre au CSS (autour des caractères {|}|:|;|,|>)
    sed 's/ *{ */{/g; s/ *} */}/g; s/ *: */:/g; s/ *; */;/g; s/ *, */,/g; s/ *> */>/g' > "$2" || exit 1
}

# ------------------------------------------------------------------------------
# Rôle : 
#   Recrée l'arborescence, copie les fichiers standards, et lance la minification
#   sur les fichiers HTML et CSS. Gère la suppression du dossier existant.
#
# Paramètres attendus : 
#   $1 : (DIR_SOURCE) Chemin vers le répertoire d'origine
#   $2 : (DIR_DEST) Chemin vers le répertoire cible
#
# Variables globales utilisées : FORCE, VERBOSE
#
# Ce que la fonction renvoie :
#   Appelle implicitement show_reduction_percent si VERBOSE=1.
# ------------------------------------------------------------------------------
recreate_tree()
{
    # gestion répertoire destination
    if ! test -e "$2"
    then
        mkdir "$2"
        if test "$?" -ne 0
        then
            echo "Directory creation failed, end of program" >&2
            exit 1
        fi
    else
        if test "$FORCE" -eq 0  # option -f
        then
            printf 'Do you want to remove "%s"? [y/n] ' "$2"
            read -r CONFIRMATION

            if test "$CONFIRMATION" != "y"
            then
                echo "Operation canceled"
                exit 0
            fi
        fi
        
        # suppression et recréation (-f ou confirmation)
        rm -rf "$2"
        mkdir "$2"
        if test "$?" -ne 0
        then
            echo "Directory creation failed, end of program" >&2
            exit 1
        fi
    fi

    # parcours et traitement de l'arborescence
    LIST=$(find "$1" | tail -n +2)  # tails -n +2 -> retire le ./
    for SRC_PATH in $LIST
    do
        REL_PATH="${SRC_PATH#$1}"   # '#' substitution de caractère, on garde uniquement le chemin à l'intérieur du répertoire
        DEST_PATH="$2$REL_PATH"

        if test -d "$SRC_PATH"      # création des répertoires
        then
            mkdir "$DEST_PATH" || exit 1
        elif test -f "$SRC_PATH"    # création des fichiers réguliers (en fonction de l'extension)
        then
            case "$SRC_PATH" in
                *.html)
                    minifie_HTML "$SRC_PATH" "$DEST_PATH" "$TAGS_FILE"
                    if test "$VERBOSE" -eq 1
                    then
                        show_reduction_percent "HTML" "$SRC_PATH" "$DEST_PATH"
                    fi
                    ;;
                *.css)
                    minifie_CSS "$SRC_PATH" "$DEST_PATH"
                    if test "$VERBOSE" -eq 1
                    then
                        show_reduction_percent "CSS" "$SRC_PATH" "$DEST_PATH"
                    fi
                    ;;
                *)
                    # les autres fichiers sont copiés
                    cp "$SRC_PATH" "$DEST_PATH"
                    ;;
            esac
        fi
    done
}


#    __    __     ______     __     __   __    
#   /\ "-./  \   /\  __ \   /\ \   /\ "-.\ \   
#   \ \ \-./\ \  \ \  __ \  \ \ \  \ \ \-.  \  
#    \ \_\ \ \_\  \ \_\ \_\  \ \_\  \ \_\\"\_\ 
#     \/_/  \/_/   \/_/\/_/   \/_/   \/_/ \/_/                             

# vérification de --help
if test "$1" = "--help"
then
    if test "$#" -eq 1
    then
        help
        exit 0
    else
        echo "The \"--help\" option must be used alone" >&2
        echo "Enter \"$0 --help\" for more information." >&2
        exit 1
    fi
fi

# initialisation variables globales (FLAGS)
VERBOSE=0
FORCE=0
TAGS_FILE=""

# parcours des arguments
while test "$#" -gt 0
do
    # si une option est présente, on lève un flag, pour vérifier qu'on ne la rencontre pas plusieurs fois
    case "$1" in
        -v)
            if test "$VERBOSE" -eq 1
            then
                echo "The \"-v\" option cannot be specified more than once" >&2
                echo "Enter \"$0 --help\" for more information." >&2
                exit 1
            fi
            VERBOSE=1
            ;;

        -f)
            if test "$FORCE" -eq 1
            then
                echo "The \"-f\" option cannot be specified more than once" >&2
                echo "Enter \"$0 --help\" for more information." >&2
                exit 1
            fi
            FORCE=1
            ;;

        -t)
            if test -n "$TAGS_FILE"
            then
                echo "The \"-t\" option cannot be specified more than once" >&2
                echo "Enter \"$0 --help\" for more information." >&2
                exit 1
            fi

            shift

            if test "$#" -eq 0
            then
                echo "The \"-t\" option must be followed by a file" >&2
                echo "Enter \"$0 --help\" for more information." >&2
                exit 1
            fi

            if test ! -f "$1" || test ! -r "$1"
            then
                echo "The TAGS_FILE must be an existing readable file" >&2
                echo "Enter \"$0 --help\" for more information." >&2
                exit 1
            fi

            TAGS_FILE="$1"
            ;;

        -*) # option inconnue
            echo "The \"$1\" option is not supported" >&2
            echo "Enter \"$0 --help\" for more information." >&2
            exit 1
            ;;

        *)
            break
            ;;
    esac
    shift
done

# vérification arguments positionnels DIR_SOURCE et DIR_DEST
if test "$#" -lt 2
then
    echo "Paths to \"DIR_SOURCE\" and \"DIR_DEST\" directories must be specified" >&2
    echo "Enter \"$0 --help\" for more information." >&2
    exit 1
elif test "$#" -gt 2
then
    echo "Too many arguments, or options placed after the directories." >&2
    echo "Enter \"$0 --help\" for more information." >&2
    exit 1
fi

# nettoyage slash de fin pour éviter erreurs de cheminement ("dir/" -> "dir")
DIR_SOURCE="${1%/}"
DIR_DEST="${2%/}"

# validation des repertoires
if test ! -d "$DIR_SOURCE"
then
    echo "\"$DIR_SOURCE\" is not a directory" >&2
    echo "Enter \"$0 --help\" for more information." >&2
    exit 1
fi

if test "$DIR_SOURCE" = "$DIR_DEST"
then
    echo "DIR_SOURCE and DIR_DEST must be different" >&2
    echo "Enter \"$0 --help\" for more information." >&2
    exit 1
fi

# execution principale
recreate_tree "$DIR_SOURCE" "$DIR_DEST"

exit 0
