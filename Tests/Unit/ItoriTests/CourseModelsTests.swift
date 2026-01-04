//
//  CourseModelsTests.swift
//  ItoriTests
//
//  Tests for CourseModels - Course, Semester, and related enums
//

import XCTest
@testable import Roots

@MainActor
final class CourseModelsTests: BaseTestCase {
    
    // MARK: - EducationLevel Tests
    
    func testEducationLevelSemesterTypes() {
        // Test that each education level returns correct semester types
        XCTAssertEqual(EducationLevel.middleSchool.semesterTypes.count, 4)
        XCTAssertTrue(EducationLevel.middleSchool.semesterTypes.contains(.fall))
        
        XCTAssertEqual(EducationLevel.college.semesterTypes.count, 4)
        XCTAssertTrue(EducationLevel.college.semesterTypes.contains(.winter))
        
        XCTAssertEqual(EducationLevel.gradSchool.semesterTypes.count, 5)
    }
    
    func testEducationLevelAllCases() {
        XCTAssertEqual(EducationLevel.allCases.count, 4)
        XCTAssertTrue(EducationLevel.allCases.contains(.college))
    }
    
    // MARK: - Semester Tests
    
    func testSemesterInitialization() {
        let start = date(year: 2024, month: 9, day: 1)
        let end = date(year: 2024, month: 12, day: 20)
        
        let semester = Semester(
            startDate: start,
            endDate: end,
            isCurrent: true,
            educationLevel: .college,
            semesterTerm: .fall
        )
        
        XCTAssertEqual(semester.startDate, start)
        XCTAssertEqual(semester.endDate, end)
        XCTAssertTrue(semester.isCurrent)
        XCTAssertEqual(semester.educationLevel, .college)
        XCTAssertEqual(semester.semesterTerm, .fall)
        XCTAssertFalse(semester.isArchived)
    }
    
    func testSemesterDefaultName() {
        let start = date(year: 2024, month: 9, day: 1)
        let end = date(year: 2024, month: 12, day: 20)
        
        let semester = Semester(
            startDate: start,
            endDate: end,
            semesterTerm: .fall
        )
        
        XCTAssertTrue(semester.defaultName.contains("Fall"))
        XCTAssertTrue(semester.defaultName.contains("2024"))
    }
    
    func testSemesterCodable() throws {
        let semester = mockData.createSemester()
        
        // Encode
        let encoder = JSONEncoder()
        let data = try encoder.encode(semester)
        
        // Decode
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(Semester.self, from: data)
        
        XCTAssertEqual(decoded.id, semester.id)
        XCTAssertEqual(decoded.educationLevel, semester.educationLevel)
        assertDatesEqual(decoded.startDate, semester.startDate)
    }
    
    func testSemesterWithGradProgram() {
        let semester = Semester(
            startDate: Date(),
            endDate: Date(),
            educationLevel: .gradSchool,
            semesterTerm: .fall,
            gradProgram: .phd
        )
        
        XCTAssertEqual(semester.gradProgram, .phd)
        XCTAssertEqual(semester.educationLevel, .gradSchool)
    }
    
    // MARK: - Course Tests
    
    func testCourseInitialization() {
        let course = Course(
            title: "Computer Science 101",
            code: "CS101",
            semesterId: UUID(),
            courseType: .regular,
            instructor: "Dr. Smith",
            credits: 3.0
        )
        
        XCTAssertEqual(course.title, "Computer Science 101")
        XCTAssertEqual(course.code, "CS101")
        XCTAssertEqual(course.courseType, .regular)
        XCTAssertEqual(course.instructor, "Dr. Smith")
        XCTAssertEqual(course.credits, 3.0)
        XCTAssertFalse(course.isArchived)
    }
    
    func testCourseTypes() {
        XCTAssertEqual(CourseType.regular.rawValue, "Regular")
        XCTAssertEqual(CourseType.ap.rawValue, "AP")
        XCTAssertEqual(CourseType.honors.rawValue, "Honors")
        XCTAssertTrue(CourseType.allCases.count >= 10)
    }
    
    func testCourseCodable() throws {
        let course = mockData.createCourse()
        
        // Encode
        let encoder = JSONEncoder()
        let data = try encoder.encode(course)
        
        // Decode
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(Course.self, from: data)
        
        XCTAssertEqual(decoded.id, course.id)
        XCTAssertEqual(decoded.title, course.title)
        XCTAssertEqual(decoded.code, course.code)
    }
    
    func testCourseWithAttachments() {
        // Test course with attachments
        let attachments = [
            Attachment(id: UUID(), name: "syllabus.pdf", localURL: URL(string: "file://test"), dateAdded: Date())
        ]
        
        let course = Course(
            title: "Test",
            code: "TEST",
            semesterId: UUID(),
            attachments: attachments
        )
        
        XCTAssertEqual(course.attachments.count, 1)
        XCTAssertEqual(course.attachments.first?.name, "syllabus.pdf")
    }
    
    // MARK: - Credit Type Tests
    
    func testCreditTypes() {
        XCTAssertEqual(CreditType.credits.rawValue, "Credits")
        XCTAssertEqual(CreditType.units.rawValue, "Units")
        XCTAssertEqual(CreditType.hours.rawValue, "Hours")
        XCTAssertEqual(CreditType.none.rawValue, "None")
    }
    
    // MARK: - Edge Cases
    
    func testSemesterBackwardsDate() {
        // End before start - should still work (validation is business logic)
        let start = date(year: 2024, month: 12, day: 1)
        let end = date(year: 2024, month: 9, day: 1)
        
        let semester = Semester(startDate: start, endDate: end)
        XCTAssertNotNil(semester)
    }
    
    func testCourseEmptyStrings() {
        let course = Course(
            title: "",
            code: "",
            semesterId: UUID()
        )
        
        XCTAssertEqual(course.title, "")
        XCTAssertEqual(course.code, "")
    }
    
    func testCourseNegativeCredits() {
        let course = Course(
            title: "Test",
            code: "TEST",
            semesterId: UUID(),
            credits: -1.0
        )
        
        XCTAssertEqual(course.credits, -1.0)
    }
    
    // MARK: - SemesterType Tests
    
    func testSemesterTypeAllCases() {
        XCTAssertEqual(SemesterType.fall.rawValue, "Fall")
        XCTAssertEqual(SemesterType.spring.rawValue, "Spring")
        XCTAssertEqual(SemesterType.winter.rawValue, "Winter")
        XCTAssertEqual(SemesterType.summerI.rawValue, "Summer I")
        XCTAssertEqual(SemesterType.summerII.rawValue, "Summer II")
    }
    
    // MARK: - GradSchoolProgram Tests
    
    func testGradSchoolProgramTypes() {
        XCTAssertEqual(GradSchoolProgram.masters.rawValue, "Master's (MA/MS)")
        XCTAssertEqual(GradSchoolProgram.phd.rawValue, "PhD")
        XCTAssertEqual(GradSchoolProgram.md.rawValue, "MD")
        XCTAssertEqual(GradSchoolProgram.jd.rawValue, "JD")
        XCTAssertEqual(GradSchoolProgram.mba.rawValue, "MBA")
        XCTAssertEqual(GradSchoolProgram.mfa.rawValue, "MFA")
        XCTAssertEqual(GradSchoolProgram.edd.rawValue, "EdD")
    }
}
