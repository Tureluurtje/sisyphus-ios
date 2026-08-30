import SwiftData
import Foundation

@Model
class WordList {
    var listId: UUID
    var schoolYear: String // "25-26"
    var schoolGrade: Int // 1-6
    var chapters: [Chapter]
    
    init(listId: UUID, schoolYear: String, schoolGrade: Int, chapters: [Chapter]) {
        self.listId = listId
        self.schoolYear = schoolYear
        self.schoolGrade = schoolGrade
        self.chapters = chapters
    }
}

@Model
class Chapter {
    var chapterId: UUID
    var name: String // "h31-32"
    var words: [Word]
    
    init(chapterId: UUID, name: String, words: [Word]) {
        self.chapterId = chapterId
        self.name = name
        self.words = words
    }
}

@Model
class Word {
    var wordId: UUID
    var chapterId: UUID
    var word: String
    var translation: String
    var targetDate: Date
    
    init(wordId: UUID, chapterId: UUID, word: String, translation: String, targetDate: Date) {
        self.wordId = wordId
        self.chapterId = chapterId
        self.word = word
        self.translation = translation
        self.targetDate = targetDate
    }
}

@Model
class WordResult {
    var wordId: UUID
    var chapterId: UUID
    var reviewedAt: Date
    
    var correct: Int
    var inCorrect: Int
    
    init(wordId: UUID, chapterId: UUID, reviewedAt: Date, correct: Int, inCorrect: Int) {
        self.wordId = wordId
        self.chapterId = chapterId
        self.reviewedAt = reviewedAt
        self.correct = correct
        self.inCorrect = inCorrect
    }
}

struct DueWord: Codable, Sendable {
    let wordId: UUID
    let chapterId: UUID
    let word: String
    let translation: String
}
