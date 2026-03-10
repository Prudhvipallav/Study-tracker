"""
StudentTrack Pro — Flashcard System Module
Decks, study mode (flip cards), quiz mode, accuracy tracking, XP awards.
"""

import customtkinter as ctk
import random
from database import db
from modules.theme_manager import ThemeManager

DIFFICULTY_COLORS = {"easy": "#3FB950", "medium": "#D29922", "hard": "#F85149"}


class FlashcardsModule(ctk.CTkFrame):
    def __init__(self, parent, profile_id, tm: ThemeManager, refresh_xp_cb):
        super().__init__(parent, fg_color=tm.background, corner_radius=0)
        self._pid = profile_id
        self._tm = tm
        self._refresh_xp = refresh_xp_cb
        self._view = "decks"  # 'decks', 'study', 'quiz'
        self._active_deck = None
        self._build()

    def _build(self):
        tm = self._tm
        self._header = ctk.CTkFrame(self, fg_color=tm.surface, corner_radius=0, height=60)
        self._header.pack(fill="x")
        self._header.pack_propagate(False)
        ctk.CTkLabel(self._header, text="🃏 Flashcards",
                     font=ctk.CTkFont(size=20, weight="bold"),
                     text_color=tm.primary).pack(side="left", padx=20)
        ctk.CTkButton(self._header, text="+ New Deck", width=110, height=34,
                      fg_color=tm.primary, hover_color=tm.secondary, corner_radius=8,
                      command=self._add_deck).pack(side="right", padx=20)

        self._content = ctk.CTkScrollableFrame(self, fg_color=tm.background, corner_radius=0)
        self._content.pack(fill="both", expand=True)
        self._render_decks()

    def _render_decks(self):
        self._clear_content()
        tm = self._tm
        decks = db.fetch_all(
            "SELECT * FROM flashcard_decks WHERE profile_id=? ORDER BY created_at DESC",
            [self._pid]
        )
        if not decks:
            ctk.CTkLabel(self._content, text="No decks yet! Create one above 🃏",
                         font=ctk.CTkFont(size=15), text_color=tm.text_secondary).pack(pady=60)
            return

        grid = ctk.CTkFrame(self._content, fg_color="transparent")
        grid.pack(fill="x", padx=16, pady=10)
        grid.columnconfigure((0, 1, 2), weight=1)

        for i, deck in enumerate(decks):
            row, col = divmod(i, 3)
            card_count = db.fetch_one("SELECT COUNT(*) as c FROM flashcards WHERE deck_id=?", [deck["id"]])
            count = card_count["c"] if card_count else 0

            card = ctk.CTkFrame(grid, fg_color=tm.card, corner_radius=12,
                                border_width=2, border_color=deck["color"] or tm.primary)
            card.grid(row=row, column=col, padx=8, pady=8, sticky="nsew")

            ctk.CTkLabel(card, text=deck["name"],
                         font=ctk.CTkFont(size=14, weight="bold"),
                         text_color=tm.text).pack(pady=(16, 2))
            if deck["subject"]:
                ctk.CTkLabel(card, text=deck["subject"],
                             font=ctk.CTkFont(size=11), text_color=tm.text_secondary).pack()
            ctk.CTkLabel(card, text=f"{count} cards",
                         font=ctk.CTkFont(size=12), text_color=deck["color"] or tm.primary).pack(pady=4)

            btn_row = ctk.CTkFrame(card, fg_color="transparent")
            btn_row.pack(pady=(4, 14))

            deck_id = deck["id"]
            ctk.CTkButton(btn_row, text="📖 Study", width=76, height=30,
                          fg_color=tm.primary, hover_color=tm.secondary, corner_radius=6,
                          command=lambda did=deck_id: self._start_study(did)).pack(side="left", padx=3)
            ctk.CTkButton(btn_row, text="❓ Quiz", width=70, height=30,
                          fg_color=tm.accent, hover_color=tm.warning, corner_radius=6,
                          command=lambda did=deck_id: self._start_quiz(did)).pack(side="left", padx=3)
            ctk.CTkButton(btn_row, text="+ Card", width=64, height=30,
                          fg_color=tm.surface2, hover_color=tm.surface, text_color=tm.text,
                          corner_radius=6,
                          command=lambda did=deck_id: self._add_card(did)).pack(side="left", padx=3)

    def _start_study(self, deck_id: int):
        cards = db.fetch_all("SELECT * FROM flashcards WHERE deck_id=?", [deck_id])
        if not cards:
            return
        StudySession(self, deck_id, cards, self._pid, self._tm, self._refresh_xp, self._render_decks)

    def _start_quiz(self, deck_id: int):
        cards = db.fetch_all("SELECT * FROM flashcards WHERE deck_id=?", [deck_id])
        if not cards:
            return
        QuizSession(self, deck_id, cards, self._pid, self._tm, self._refresh_xp, self._render_decks)

    def _add_deck(self):
        AddDeckDialog(self, self._pid, self._tm, self._render_decks)

    def _add_card(self, deck_id: int):
        AddCardDialog(self, deck_id, self._tm, self._render_decks)

    def _clear_content(self):
        for w in self._content.winfo_children():
            w.destroy()


class StudySession(ctk.CTkToplevel):
    def __init__(self, parent, deck_id, cards, profile_id, tm, refresh_xp_cb, on_done_cb):
        super().__init__(parent)
        self._cards = list(cards)
        random.shuffle(self._cards)
        self._idx = 0
        self._pid = profile_id
        self._tm = tm
        self._refresh_xp = refresh_xp_cb
        self._on_done = on_done_cb
        self._showing_answer = False
        self.title("Study Mode")
        self.geometry("600x420")
        self.grab_set()
        self.configure(fg_color=tm.background)
        self._build()

    def _build(self):
        tm = self._tm
        self._progress_lbl = ctk.CTkLabel(self, text="",
                                           font=ctk.CTkFont(size=13), text_color=tm.text_secondary)
        self._progress_lbl.pack(pady=10)

        self._card_frame = ctk.CTkFrame(self, fg_color=tm.card, corner_radius=16,
                                         border_width=2, border_color=tm.primary)
        self._card_frame.pack(fill="both", expand=True, padx=30, pady=10)
        self._card_frame.bind("<Button-1>", lambda e: self._flip())

        self._card_lbl = ctk.CTkLabel(self._card_frame, text="",
                                       font=ctk.CTkFont(size=18), text_color=tm.text,
                                       wraplength=500, justify="center")
        self._card_lbl.place(relx=0.5, rely=0.5, anchor="center")
        self._card_lbl.bind("<Button-1>", lambda e: self._flip())

        self._hint_lbl = ctk.CTkLabel(self, text="Click card to flip",
                                       font=ctk.CTkFont(size=12), text_color=tm.text_secondary)
        self._hint_lbl.pack()

        btn_row = ctk.CTkFrame(self, fg_color="transparent")
        btn_row.pack(pady=10)

        self._easy_btn = ctk.CTkButton(btn_row, text="😊 Easy", width=90, height=36,
                                        fg_color=tm.success, corner_radius=8,
                                        state="disabled",
                                        command=lambda: self._mark("easy"))
        self._easy_btn.pack(side="left", padx=6)

        self._hard_btn = ctk.CTkButton(btn_row, text="😓 Hard", width=90, height=36,
                                        fg_color=tm.warning, corner_radius=8,
                                        state="disabled",
                                        command=lambda: self._mark("hard"))
        self._hard_btn.pack(side="left", padx=6)

        self._wrong_btn = ctk.CTkButton(btn_row, text="❌ Wrong", width=90, height=36,
                                         fg_color=tm.danger, corner_radius=8,
                                         state="disabled",
                                         command=lambda: self._mark("wrong"))
        self._wrong_btn.pack(side="left", padx=6)

        self._show_card()

    def _show_card(self):
        if self._idx >= len(self._cards):
            self._finish()
            return
        card = self._cards[self._idx]
        self._showing_answer = False
        self._card_lbl.configure(text=card["question"], text_color=self._tm.text)
        self._progress_lbl.configure(text=f"Card {self._idx + 1} of {len(self._cards)}")
        self._hint_lbl.configure(text="Click card to reveal answer")
        for btn in [self._easy_btn, self._hard_btn, self._wrong_btn]:
            btn.configure(state="disabled")

    def _flip(self):
        if self._showing_answer:
            return
        card = self._cards[self._idx]
        self._showing_answer = True
        self._card_lbl.configure(text=card["answer"], text_color=self._tm.secondary)
        self._hint_lbl.configure(text="How did you do?")
        for btn in [self._easy_btn, self._hard_btn, self._wrong_btn]:
            btn.configure(state="normal")

    def _mark(self, result: str):
        card = self._cards[self._idx]
        if result == "easy":
            db.update("flashcards", {"times_correct": card["times_correct"] + 1}, {"id": card["id"]})
            db.award_xp(self._pid, 2, "Flashcard easy")
        elif result in ("hard", "wrong"):
            db.update("flashcards", {"times_wrong": card["times_wrong"] + 1}, {"id": card["id"]})
        self._idx += 1
        self._refresh_xp()
        self._show_card()

    def _finish(self):
        db.award_xp(self._pid, 8, "Completed flashcard study session")
        db.check_and_award_badges(self._pid)
        self._refresh_xp()
        self.destroy()
        self._on_done()


class QuizSession(ctk.CTkToplevel):
    def __init__(self, parent, deck_id, cards, profile_id, tm, refresh_xp_cb, on_done_cb):
        super().__init__(parent)
        self._cards = list(cards)
        random.shuffle(self._cards)
        self._idx = 0
        self._correct = 0
        self._pid = profile_id
        self._tm = tm
        self._refresh_xp = refresh_xp_cb
        self._on_done = on_done_cb
        self.title("Quiz Mode")
        self.geometry("550x380")
        self.grab_set()
        self.configure(fg_color=tm.background)
        self._build()

    def _build(self):
        tm = self._tm
        self._q_lbl = ctk.CTkLabel(self, text="", font=ctk.CTkFont(size=16, weight="bold"),
                                    text_color=tm.text, wraplength=480, justify="center")
        self._q_lbl.pack(pady=30)

        self._ans_var = ctk.StringVar()
        self._entry = ctk.CTkEntry(self, textvariable=self._ans_var, width=380, height=40,
                                    fg_color=tm.surface, border_color=tm.border, text_color=tm.text,
                                    corner_radius=10, font=ctk.CTkFont(size=13))
        self._entry.pack(pady=8)

        self._feedback_lbl = ctk.CTkLabel(self, text="",
                                           font=ctk.CTkFont(size=13), text_color=tm.success)
        self._feedback_lbl.pack()

        ctk.CTkButton(self, text="Submit", width=160, height=40,
                      fg_color=tm.primary, hover_color=tm.secondary, corner_radius=10,
                      font=ctk.CTkFont(size=14, weight="bold"),
                      command=self._check).pack(pady=10)

        self._score_lbl = ctk.CTkLabel(self, text="",
                                        font=ctk.CTkFont(size=12), text_color=tm.text_secondary)
        self._score_lbl.pack()

        self._entry.bind("<Return>", lambda e: self._check())
        self._next_question()

    def _next_question(self):
        if self._idx >= len(self._cards):
            self._finish()
            return
        card = self._cards[self._idx]
        self._q_lbl.configure(text=card["question"])
        self._ans_var.set("")
        self._feedback_lbl.configure(text="")
        self._score_lbl.configure(text=f"Question {self._idx + 1}/{len(self._cards)}  ·  Score: {self._correct}")
        self._entry.focus()

    def _check(self):
        card = self._cards[self._idx]
        ans = self._ans_var.get().strip().lower()
        correct = card["answer"].strip().lower()
        if ans == correct or ans in correct or correct.startswith(ans):
            self._feedback_lbl.configure(text="✅ Correct!", text_color=self._tm.success)
            self._correct += 1
            db.update("flashcards", {"times_correct": card["times_correct"] + 1}, {"id": card["id"]})
        else:
            self._feedback_lbl.configure(text=f"❌ Correct answer: {card['answer']}", text_color=self._tm.danger)
            db.update("flashcards", {"times_wrong": card["times_wrong"] + 1}, {"id": card["id"]})
        self._idx += 1
        self.after(1200, self._next_question)

    def _finish(self):
        score_pct = int(self._correct / len(self._cards) * 100) if self._cards else 0
        db.award_xp(self._pid, score_pct // 10, "Completed quiz")
        self._refresh_xp()
        for w in self.winfo_children():
            w.destroy()
        tm = self._tm
        ctk.CTkLabel(self, text="Quiz Complete! 🎉",
                     font=ctk.CTkFont(size=22, weight="bold"),
                     text_color=tm.primary).pack(pady=30)
        ctk.CTkLabel(self, text=f"Score: {self._correct}/{len(self._cards)} ({score_pct}%)",
                     font=ctk.CTkFont(size=18), text_color=tm.text).pack()
        ctk.CTkButton(self, text="Done", width=120, height=40,
                      fg_color=tm.primary, corner_radius=10,
                      command=lambda: (self.destroy(), self._on_done())).pack(pady=24)


class AddDeckDialog(ctk.CTkToplevel):
    def __init__(self, parent, profile_id, tm, on_save_cb):
        super().__init__(parent)
        self._pid = profile_id
        self._tm = tm
        self._on_save = on_save_cb
        self.title("New Deck")
        self.geometry("380x300")
        self.resizable(False, False)
        self.grab_set()
        self.configure(fg_color=tm.background)
        self._build()

    def _build(self):
        tm = self._tm
        ctk.CTkLabel(self, text="New Flashcard Deck",
                     font=ctk.CTkFont(size=16, weight="bold"), text_color=tm.text).pack(pady=16)
        self._name = ctk.StringVar()
        self._subj = ctk.StringVar()
        self._color = ctk.StringVar(value=tm.primary)
        for label, var in [("Deck Name *", self._name), ("Subject", self._subj), ("Color (hex)", self._color)]:
            ctk.CTkLabel(self, text=label, font=ctk.CTkFont(size=12),
                         text_color=tm.text_secondary, anchor="w").pack(anchor="w", padx=20, pady=(6, 2))
            ctk.CTkEntry(self, textvariable=var, height=34, fg_color=tm.surface,
                         border_color=tm.border, text_color=tm.text, corner_radius=8).pack(fill="x", padx=20)
        ctk.CTkButton(self, text="Create", width=160, height=40,
                      fg_color=tm.primary, corner_radius=10,
                      command=self._save).pack(pady=18)

    def _save(self):
        name = self._name.get().strip()
        if not name:
            return
        db.insert("flashcard_decks", {
            "profile_id": self._pid, "name": name,
            "subject": self._subj.get().strip(), "color": self._color.get().strip()
        })
        db.award_xp(self._pid, 10, "Created flashcard deck")
        db.check_and_award_badges(self._pid)
        self.destroy()
        self._on_save()


class AddCardDialog(ctk.CTkToplevel):
    def __init__(self, parent, deck_id, tm, on_save_cb):
        super().__init__(parent)
        self._deck_id = deck_id
        self._tm = tm
        self._on_save = on_save_cb
        self._diff = ctk.StringVar(value="medium")
        self.title("Add Card")
        self.geometry("420x360")
        self.resizable(False, False)
        self.grab_set()
        self.configure(fg_color=tm.background)
        self._build()

    def _build(self):
        tm = self._tm
        ctk.CTkLabel(self, text="Add Flashcard", font=ctk.CTkFont(size=16, weight="bold"),
                     text_color=tm.text).pack(pady=14)
        self._q = ctk.StringVar()
        self._a = ctk.StringVar()
        for label, var in [("Question (front) *", self._q), ("Answer (back) *", self._a)]:
            ctk.CTkLabel(self, text=label, font=ctk.CTkFont(size=12),
                         text_color=tm.text_secondary, anchor="w").pack(anchor="w", padx=20, pady=(8, 2))
            ctk.CTkEntry(self, textvariable=var, height=36, fg_color=tm.surface,
                         border_color=tm.border, text_color=tm.text, corner_radius=8).pack(fill="x", padx=20)
        ctk.CTkLabel(self, text="Difficulty:", font=ctk.CTkFont(size=12),
                     text_color=tm.text_secondary, anchor="w").pack(anchor="w", padx=20, pady=(8, 2))
        ctk.CTkSegmentedButton(self, values=["easy", "medium", "hard"],
                               variable=self._diff,
                               fg_color=tm.surface, selected_color=tm.primary,
                               text_color=tm.text).pack(anchor="w", padx=20)
        ctk.CTkButton(self, text="Add Card", width=160, height=40,
                      fg_color=tm.primary, corner_radius=10,
                      command=self._save).pack(pady=18)

    def _save(self):
        q = self._q.get().strip()
        a = self._a.get().strip()
        if not q or not a:
            return
        db.insert("flashcards", {"deck_id": self._deck_id, "question": q, "answer": a,
                                  "difficulty": self._diff.get()})
        self.destroy()
        self._on_save()
