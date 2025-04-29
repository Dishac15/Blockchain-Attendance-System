// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Blockchain-based Attendance System
 * @dev Contract for tracking attendance in educational or organizational settings
 */
contract AttendanceSystem {
    address public owner;
    
    struct Course {
        string name;
        bool isActive;
        mapping(address => bool) authorizedInstructors;
    }
    
    struct AttendanceRecord {
        uint256 timestamp;
        bool isPresent;
    }
    
    // courseId => Course
    mapping(uint256 => Course) public courses;
    
    // courseId => (sessionId => (studentAddress => AttendanceRecord))
    mapping(uint256 => mapping(uint256 => mapping(address => AttendanceRecord))) public attendance;
    
    // Track all registered students
    mapping(address => bool) public registeredStudents;
    
    // Track course IDs
    uint256 public courseCounter;
    
    // Events
    event CourseCreated(uint256 indexed courseId, string name);
    event AttendanceMarked(uint256 indexed courseId, uint256 indexed sessionId, address indexed student, bool isPresent, uint256 timestamp);
    event InstructorAuthorized(uint256 indexed courseId, address instructor);
    
    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }
    
    modifier onlyAuthorized(uint256 _courseId) {
        require(
            msg.sender == owner || courses[_courseId].authorizedInstructors[msg.sender],
            "Not authorized"
        );
        _;
    }
    
    constructor() {
        owner = msg.sender;
        courseCounter = 0;
    }
    
    /**
     * @dev Create a new course and authorize instructors
     * @param _name Name of the course
     * @param _instructors Array of instructor addresses to authorize
     * @return courseId The ID of the newly created course
     */
    function createCourse(string memory _name, address[] memory _instructors) public onlyOwner returns (uint256) {
        uint256 courseId = courseCounter++;
        
        Course storage newCourse = courses[courseId];
        newCourse.name = _name;
        newCourse.isActive = true;
        
        // Authorize instructors
        for (uint i = 0; i < _instructors.length; i++) {
            newCourse.authorizedInstructors[_instructors[i]] = true;
            emit InstructorAuthorized(courseId, _instructors[i]);
        }
        
        emit CourseCreated(courseId, _name);
        return courseId;
    }
    
    /**
     * @dev Mark attendance for a student
     * @param _courseId ID of the course
     * @param _sessionId ID of the session
     * @param _student Address of the student
     * @param _isPresent Boolean indicating if the student is present
     */
    function markAttendance(
        uint256 _courseId,
        uint256 _sessionId,
        address _student,
        bool _isPresent
    ) public onlyAuthorized(_courseId) {
        require(courses[_courseId].isActive, "Course is not active");
        
        // Register student if they're not already registered
        if (!registeredStudents[_student]) {
            registeredStudents[_student] = true;
        }
        
        // Record attendance
        attendance[_courseId][_sessionId][_student] = AttendanceRecord({
            timestamp: block.timestamp,
            isPresent: _isPresent
        });
        
        emit AttendanceMarked(_courseId, _sessionId, _student, _isPresent, block.timestamp);
    }
    
    /**
     * @dev Verify attendance for a student
     * @param _courseId ID of the course
     * @param _sessionId ID of the session
     * @param _student Address of the student
     * @return isPresent Boolean indicating if the student was present
     * @return timestamp Timestamp when the attendance was recorded
     */
    function verifyAttendance(
        uint256 _courseId,
        uint256 _sessionId,
        address _student
    ) public view returns (bool isPresent, uint256 timestamp) {
        AttendanceRecord memory record = attendance[_courseId][_sessionId][_student];
        return (record.isPresent, record.timestamp);
    }
    
    /**
     * @dev Get student attendance count across all sessions for a specific course
     * @param _courseId ID of the course
     * @param _student Address of the student
     * @param _totalSessions Total number of sessions to check (from session 0 to _totalSessions-1)
     * @return presentCount Number of sessions the student was present for
     */
    function getStudentAttendanceCount(
        uint256 _courseId,
        address _student,
        uint256 _totalSessions
    ) public view returns (uint256 presentCount) {
        require(_totalSessions > 0, "Total sessions must be greater than zero");
        
        uint256 count = 0;
        for (uint256 i = 0; i < _totalSessions; i++) {
            if (attendance[_courseId][i][_student].isPresent) {
                count++;
            }
        }
        
        return count;
    }
    
    /**
     * @dev Bulk mark attendance for multiple students in a single transaction
     * @param _courseId ID of the course
     * @param _sessionId ID of the session
     * @param _students Array of student addresses
     * @param _arePresent Array of attendance statuses corresponding to each student
     */
    function bulkMarkAttendance(
        uint256 _courseId,
        uint256 _sessionId,
        address[] memory _students,
        bool[] memory _arePresent
    ) public onlyAuthorized(_courseId) {
        require(courses[_courseId].isActive, "Course is not active");
        require(_students.length == _arePresent.length, "Arrays length mismatch");
        require(_students.length > 0, "Empty arrays provided");
        
        for (uint256 i = 0; i < _students.length; i++) {
            address student = _students[i];
            bool isPresent = _arePresent[i];
            
            // Register student if they're not already registered
            if (!registeredStudents[student]) {
                registeredStudents[student] = true;
            }
            
            // Record attendance
            attendance[_courseId][_sessionId][student] = AttendanceRecord({
                timestamp: block.timestamp,
                isPresent: isPresent
            });
            
            emit AttendanceMarked(_courseId, _sessionId, student, isPresent, block.timestamp);
        }
    }
}
