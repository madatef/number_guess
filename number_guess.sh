#!/bin/bash


# Set PSQL command with username
PSQL="psql --username=freecodecamp --dbname=number_guess -t --no-align -c"


# Welcome the user
echo "Enter your username:"
read USERNAME

# Check if the user exists in the database
USER_INFO=$($PSQL "SELECT user_id, games_played, best_game FROM users WHERE username = '$USERNAME'")

# If the user does not exist, insert a new record
if [[ -z $USER_INFO ]]; then
  echo "Welcome, $USERNAME! It looks like this is your first time here."
  INSERT_USER=$($PSQL "INSERT INTO users(username, games_played, best_game) VALUES('$USERNAME', 0, NULL)")
else
  # Parse the user info
  IFS="|" read USER_ID GAMES_PLAYED BEST_GAME <<< "$USER_INFO"
  echo "Welcome back, $USERNAME! You have played $GAMES_PLAYED games, and your best game took $BEST_GAME guesses."
fi

# Generate a random number between 1 and 1000
TARGET_NUMBER=$(( RANDOM % 1000 + 1 ))


# Start the guessing game
echo "Guess the secret number between 1 and 1000:"
GUESS_COUNT=0
while true; do
  read GUESS
  # Validate input
  if ! [[ $GUESS =~ ^[0-9]+$ ]]; then
    echo "That is not an integer, guess again:"
    continue
  fi

  # Increment guess count
  GUESS_COUNT=$((GUESS_COUNT + 1))

  # Check the guess
  if [[ $GUESS -lt $TARGET_NUMBER ]]; then
    echo "It's higher than that, guess again:"
  elif [[ $GUESS -gt $TARGET_NUMBER ]]; then
    echo "It's lower than that, guess again:"
  else
    echo "You guessed it in $GUESS_COUNT tries. The secret number was $TARGET_NUMBER. Nice job!"

    # Update user data
    if [[ -z $USER_INFO ]]; then
      # First game
      UPDATE_USER=$($PSQL "UPDATE users SET games_played = 1, best_game = $GUESS_COUNT WHERE username = '$USERNAME'")
    else
      # Update games played and best game if necessary
      NEW_GAMES_PLAYED=$((GAMES_PLAYED + 1))
      if [[ $BEST_GAME -eq 0 || $GUESS_COUNT -lt $BEST_GAME ]]; then
        UPDATE_USER=$($PSQL "UPDATE users SET games_played = $NEW_GAMES_PLAYED, best_game = $GUESS_COUNT WHERE username = '$USERNAME'")
      else
        UPDATE_USER=$($PSQL "UPDATE users SET games_played = $NEW_GAMES_PLAYED WHERE username = '$USERNAME'")
      fi
    fi

    # End the game
    break
  fi
done