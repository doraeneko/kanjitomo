
Rework the workflow of the app.
Basic functionalities:

1) Kanji detection (default function): already there
2) Composita lookup: already there
3) Learning: see rework following
4) Help: new


3) Learning:

Here let's remove RTK for now.

So, clicking "Learning" opens a window with two sections:
a) JLPT
Offers these subfunctions: 
I) Review 
II) Edit review options (for selecting which kanjis)
III) Statistics

Review options allows to select chunks and JLPT levels. Additionally (!): User can select which
composita should be included in the quiz (by an option that says "Include composita of these kanjis up to level "N1 N2 N3 N4 N5").

With this, we have the set of Kanjis K to test,
and a set of composita COMP, namely those containing a kanji of K and which are of the specified JLPT level.
We also have now a set of sentences S containing
a composita in COMP.

Now the "Review mode" should test the following:
A) Kanji both directions: meaning shown + readings, kanji has to be drawn
B) Kanji shown, user has to know the meaning + reading
C) for composita in COMP: check both directions: draw the required kanji, guess the reading (and meaning)
D) If there is even a sentence in S: check the sentence as currently done in both directions.
A Kanji is defined as "green" if A) + B) is all done. 
Track the values of these separately, all of them have to be satsified to get a "green" circle.
C + D) is similarly tracked, but does not directly contribute to the "score" for the kanji.

In the Review, the user can select to quiz either only kanji (A+B), or only composita (C+D), or both.


b) Custom
Offers these subfunctions:
I) Review
II) Edit custom list
III) Statistics: Shows statistics for the kanjis in the custom list + Composita.

Regarding II): 
The user can draw kanji, select the matching candidate and add it to the kanji list. He can also select (!) composita he wants to learn with it in the dialogue. Also for existing kanjis in th e learning list, he can add composita (or of course remove them or remove the entire kanji from the learning list).

With this, we again have a set of Kanjis K to test,
and a set of composita COMP, namely those the user selected,
and also have now a set of sentences S containing
a composita in COMP.

Now the "Review mode" should test the following:
A) Kanji both directions: meaning shown + readings, kanji has to be drawn
B) Kanji shown, user has to know the meaning + reading
C) for composita in COMP: check both directions: draw the required kanji, guess the reading (and meaning)
D) If there is even a sentence in S: check the sentence as currently done in both directions.
A Kanji is defined as "green" if A) + B) is all done. 
Track the values of these separately, all of them have to be satsified to get a "green" circle.
C + D) is similarly tracked, but does not directly contribute to the "score" for the kanji.

In the Review, the user can select to quiz either only kanji (A+B), or only composita (C+D), or both.

So you see, the review session is actually the same for both modes, please reuse code here. 


Statistics should be similar to now, the two points refer to A) and B) satisfied.

