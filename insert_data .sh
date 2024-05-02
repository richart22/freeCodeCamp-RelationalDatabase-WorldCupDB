#! /bin/bash

if [[ $1 == "test" ]]
then
  PSQL="psql --username=postgres --dbname=worldcuptest -t --no-align -c"
else
  PSQL="psql --username=freecodecamp --dbname=worldcup -t --no-align -c"
fi

# Do not change code above this line. Use the PSQL variable above to query your database.

echo $($PSQL "TRUNCATE games, teams")

cat games.csv | while IFS="," read YEAR ROUND WINNER OPPONENT W_GOALS O_GOALS
do
  # skip the title line
  if [[ $YEAR != "year" ]]
  then
    # insert team table first

    # team_id is the primary key so if the name isn't inserted into table, it can't be found
    # insert team_id according to the winner first, then the opponent
    TEAM_ID_W=$($PSQL "SELECT team_id FROM teams WHERE name = '$WINNER'")

    # if not found
    if [[ -z $TEAM_ID_W ]]
    then
      # insert name
      INSERT_TEAM_ID_W_RESULT=$($PSQL "INSERT INTO teams(name) VALUES('$WINNER')")
      if [[ $INSERT_TEAM_ID_W_RESULT == "INSERT 0 1" ]]
      then
        echo Inserted into teams, $WINNER
      fi

      # get new team_id, so that it can be inserted into games table later
      TEAM_ID_W=$($PSQL "SELECT team_id FROM teams WHERE name = '$WINNER'")
    fi

    TEAM_ID_O=$($PSQL "SELECT team_id FROM teams WHERE name = '$OPPONENT'")

    # if not found
    if [[ -z $TEAM_ID_O ]]
    then
      # insert name
      INSERT_TEAM_ID_O_RESULT=$($PSQL "INSERT INTO teams(name) VALUES('$OPPONENT')")
      if [[ $INSERT_TEAM_ID_O_RESULT == "INSERT 0 1" ]]
      then
        echo Inserted into teams, $OPPONENT
      fi

      # get new team_id, so that it can be inserted into games table later
      TEAM_ID_O=$($PSQL "SELECT team_id FROM teams WHERE name = '$OPPONENT'")
    fi

    # each row is unique in theory, but in case there's duplicate, so I use 'if'
    # each of combination of year played and winner-opponent pair is unique from eighth-final.
    GAME_ID=$($PSQL "SELECT game_id FROM games WHERE year=$YEAR AND winner_id=$TEAM_ID_W AND opponent_id=$TEAM_ID_O")

    if [[ -z $GAME_ID ]]
    then
      # insert all values into that row
      INSERT_ROW_RESULT=$($PSQL "INSERT INTO games(year, round, winner_id, opponent_id, winner_goals, opponent_goals) VALUES($YEAR, '$ROUND', $TEAM_ID_W, $TEAM_ID_O, $W_GOALS, $O_GOALS)")
      if [[ $INSERT_ROW_RESULT == "INSERT 0 1" ]]
      then
        echo Inserted into games, $YEAR $ROUND $WINNER $OPPONENT $W_GOALS $O_GOALS
      fi
    fi

  fi
done