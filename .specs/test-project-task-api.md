# Test Project: Simple Task API (Spring Boot)

**Status:** Draft
**Created:** 2026-02-12
**Last Updated:** 2026-02-12
**Purpose:** Testing project for SpecBuddy workflow validation

## Overview

A minimal RESTful API for task management built with Spring Boot. This project serves as a test case for validating the SpecBuddy workflow: creating specifications, generating implementation plans, and executing steps with the `/spec-buddy:execute` command.

The project is intentionally simple to enable fast implementation and thorough testing of SpecBuddy's capabilities across different types of development tasks.

## Goals

- **Primary Goal**: Provide a realistic test project for SpecBuddy validation
- Test specification → plan → execution workflow
- Validate step-by-step execution with `/spec-buddy:execute`
- Test different step types: setup, coding, testing, documentation
- Verify step-by-step execution with file references and run commands
- Create a runnable, functional Spring Boot application
- Document lessons learned for improving SpecBuddy

## Non-Goals

- Production-ready authentication/authorization
- Database persistence (use in-memory H2 or simple repository)
- Complex business logic or features
- Frontend implementation (API only)
- Cloud deployment configuration
- Comprehensive exception handling beyond basic validation

## Background

### Context

SpecBuddy needs validation through real-world usage. This test project will:
1. Exercise the full workflow from specification to working code
2. Identify gaps or issues in the SpecBuddy process
3. Provide examples for documentation
4. Serve as a reference implementation for Java/Spring projects

### Success Metrics

- ✅ Specification created with `/spec-buddy:new`
- ✅ Implementation plan generated
- ✅ All steps executable with `/spec-buddy:execute`
- ✅ Each step completes independently with clear success criteria
- ✅ Final API is functional and testable
- ✅ Process reveals improvement areas for SpecBuddy

## Requirements

### Functional Requirements

#### FR1: Task Entity
- **ID**: FR1
- **Priority**: P0
- **Description**: Define Task entity with JPA annotations
- **Acceptance Criteria**:
  - Task fields: id (Long), title (String), description (String), status (Enum), createdAt, updatedAt
  - Status enum: TODO, IN_PROGRESS, DONE
  - ID auto-generated
  - Timestamps auto-managed with @CreatedDate and @LastModifiedDate

#### FR2: Create Task Endpoint
- **ID**: FR2
- **Priority**: P0
- **Description**: POST /api/tasks to create new task
- **Acceptance Criteria**:
  - Endpoint: `POST /api/tasks`
  - Request body: TaskCreateRequest DTO
  - Required: title (1-200 chars)
  - Optional: description (max 1000 chars)
  - Returns: 201 Created with TaskResponse DTO
  - Validates with @Valid and returns 400 for invalid data

#### FR3: List Tasks Endpoint
- **ID**: FR3
- **Priority**: P0
- **Description**: GET /api/tasks to retrieve all tasks
- **Acceptance Criteria**:
  - Endpoint: `GET /api/tasks`
  - Optional query param: status (filter by status)
  - Returns: 200 OK with List<TaskResponse>
  - Empty list if no tasks exist

#### FR4: Get Task Endpoint
- **ID**: FR4
- **Priority**: P0
- **Description**: GET /api/tasks/{id} to retrieve single task
- **Acceptance Criteria**:
  - Endpoint: `GET /api/tasks/{id}`
  - Returns: 200 OK with TaskResponse
  - Returns: 404 Not Found if task doesn't exist
  - Custom exception: TaskNotFoundException

#### FR5: Update Task Endpoint
- **ID**: FR5
- **Priority**: P0
- **Description**: PUT /api/tasks/{id} to update task
- **Acceptance Criteria**:
  - Endpoint: `PUT /api/tasks/{id}`
  - Request body: TaskUpdateRequest DTO
  - Can update: title, description, status
  - Returns: 200 OK with TaskResponse
  - Returns: 404 if task doesn't exist
  - Returns: 400 for invalid data
  - Auto-updates `updatedAt` timestamp

#### FR6: Delete Task Endpoint
- **ID**: FR6
- **Priority**: P0
- **Description**: DELETE /api/tasks/{id} to remove task
- **Acceptance Criteria**:
  - Endpoint: `DELETE /api/tasks/{id}`
  - Returns: 204 No Content on success
  - Returns: 404 if task doesn't exist

### Non-Functional Requirements

#### NFR1: Spring Boot Best Practices
- **Priority**: P0
- **Description**: Follow Spring Boot conventions
- **Criteria**:
  - Layered architecture: Controller → Service → Repository
  - Use DTOs for requests/responses
  - Use @RestController, @Service, @Repository annotations
  - Proper dependency injection

#### NFR2: Testability
- **Priority**: P0
- **Description**: Code must be testable
- **Criteria**:
  - Include unit tests for service layer
  - Include integration tests for REST API
  - Use Spring Boot Test framework
  - MockMvc for controller testing

#### NFR3: Standard REST
- **Priority**: P0
- **Description**: Follow REST conventions
- **Criteria**:
  - Proper HTTP methods and status codes
  - JSON request/response format
  - Consistent error response structure

#### NFR4: Documentation
- **Priority**: P1
- **Description**: Include usage documentation
- **Criteria**:
  - README with API endpoints
  - Example requests/responses
  - How to build and run

## Technical Design

### Architecture

```
task-api/
├── src/
│   ├── main/
│   │   ├── java/com/example/taskapi/
│   │   │   ├── TaskApiApplication.java          # Main class
│   │   │   ├── controller/
│   │   │   │   └── TaskController.java          # REST endpoints
│   │   │   ├── service/
│   │   │   │   ├── TaskService.java             # Business logic interface
│   │   │   │   └── TaskServiceImpl.java         # Implementation
│   │   │   ├── repository/
│   │   │   │   └── TaskRepository.java          # JPA repository
│   │   │   ├── model/
│   │   │   │   ├── Task.java                    # Entity
│   │   │   │   └── TaskStatus.java              # Enum
│   │   │   ├── dto/
│   │   │   │   ├── TaskCreateRequest.java       # Create DTO
│   │   │   │   ├── TaskUpdateRequest.java       # Update DTO
│   │   │   │   └── TaskResponse.java            # Response DTO
│   │   │   └── exception/
│   │   │       ├── TaskNotFoundException.java   # Custom exception
│   │   │       └── GlobalExceptionHandler.java  # @ControllerAdvice
│   │   └── resources/
│   │       └── application.properties           # Configuration
│   └── test/
│       └── java/com/example/taskapi/
│           ├── controller/
│           │   └── TaskControllerTest.java      # Integration tests
│           └── service/
│               └── TaskServiceTest.java         # Unit tests
├── pom.xml                                       # Maven dependencies
└── README.md                                     # Documentation
```

**Technology Stack:**
- Java 17+
- Spring Boot 3.2+
- Spring Web (REST)
- Spring Data JPA
- H2 Database (in-memory)
- Lombok (reduce boilerplate)
- JUnit 5 + Mockito (testing)
- Maven

### Data Model

```java
@Entity
@Table(name = "tasks")
public class Task {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, length = 200)
    private String title;

    @Column(length = 1000)
    private String description;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private TaskStatus status;

    @CreatedDate
    private LocalDateTime createdAt;

    @LastModifiedDate
    private LocalDateTime updatedAt;
}

public enum TaskStatus {
    TODO, IN_PROGRESS, DONE
}
```

### API Endpoints

| Method | Endpoint | Description | Request Body | Response |
|--------|----------|-------------|--------------|----------|
| POST | /api/tasks | Create task | `TaskCreateRequest` | 201 + TaskResponse |
| GET | /api/tasks | List tasks | Query: `?status=TODO` | 200 + List\<TaskResponse\> |
| GET | /api/tasks/{id} | Get task | - | 200 + TaskResponse |
| PUT | /api/tasks/{id} | Update task | `TaskUpdateRequest` | 200 + TaskResponse |
| DELETE | /api/tasks/{id} | Delete task | - | 204 |

### DTOs

```java
// Request DTOs
public class TaskCreateRequest {
    @NotBlank
    @Size(min = 1, max = 200)
    private String title;

    @Size(max = 1000)
    private String description;
}

public class TaskUpdateRequest {
    @Size(min = 1, max = 200)
    private String title;

    @Size(max = 1000)
    private String description;

    private TaskStatus status;
}

// Response DTO
public class TaskResponse {
    private Long id;
    private String title;
    private String description;
    private TaskStatus status;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
}
```

### Error Responses

```json
// Validation error (400)
{
  "timestamp": "2026-02-12T10:30:00",
  "status": 400,
  "error": "Bad Request",
  "message": "Validation failed",
  "errors": [
    "title: must not be blank",
    "title: size must be between 1 and 200"
  ]
}

// Not found (404)
{
  "timestamp": "2026-02-12T10:30:00",
  "status": 404,
  "error": "Not Found",
  "message": "Task not found with id: 123"
}
```

### Example Usage

```bash
# Create task
curl -X POST http://localhost:8080/api/tasks \
  -H "Content-Type: application/json" \
  -d '{"title": "Test SpecBuddy", "description": "Create test project"}'

# List all tasks
curl http://localhost:8080/api/tasks

# Filter by status
curl http://localhost:8080/api/tasks?status=TODO

# Get specific task
curl http://localhost:8080/api/tasks/1

# Update task
curl -X PUT http://localhost:8080/api/tasks/1 \
  -H "Content-Type: application/json" \
  -d '{"status": "DONE"}'

# Delete task
curl -X DELETE http://localhost:8080/api/tasks/1
```

## Implementation Approach

### Phase 1: Setup (Testing SpecBuddy workflow)
1. Create specification (this document) with `/spec-buddy:new`
2. Create implementation plan manually
3. Test `/spec-buddy:execute` with setup steps

### Phase 2: Core Implementation
4. Execute code creation steps one by one
5. Validate each step's success criteria
6. Document any issues with SpecBuddy workflow

### Phase 3: Validation
7. Test the complete API
8. Document lessons learned
9. Identify SpecBuddy improvements

## Testing Strategy

### Unit Tests (Service Layer)
```java
@ExtendWith(MockitoExtension.class)
class TaskServiceTest {
    @Mock
    private TaskRepository repository;

    @InjectMocks
    private TaskServiceImpl service;

    @Test
    void createTask_ValidInput_ReturnsTask() {
        // Test implementation
    }
}
```

### Integration Tests (Controller Layer)
```java
@SpringBootTest
@AutoConfigureMockMvc
class TaskControllerTest {
    @Autowired
    private MockMvc mockMvc;

    @Test
    void createTask_ValidInput_Returns201() throws Exception {
        mockMvc.perform(post("/api/tasks")
            .contentType(MediaType.APPLICATION_JSON)
            .content("{\"title\":\"Test\"}"))
            .andExpect(status().isCreated());
    }
}
```

### Test Cases

**TC1: Create and Retrieve Task**
1. POST /api/tasks with valid data
2. Verify 201 response with task data
3. GET /api/tasks/{id}
4. Verify task data matches

**TC2: Update Task Status**
1. Create task (status: TODO)
2. PUT /api/tasks/{id} with status DONE
3. Verify status changed and updatedAt updated

**TC3: Filter Tasks**
1. Create tasks with different statuses
2. GET /api/tasks?status=TODO
3. Verify only TODO tasks returned

**TC4: Error Handling**
1. POST /api/tasks with missing title → 400
2. GET /api/tasks/999 → 404
3. PUT /api/tasks/999 → 404

**TC5: Validation**
1. POST /api/tasks with title > 200 chars → 400
2. POST /api/tasks with empty title → 400
3. PUT /api/tasks/{id} with invalid status → 400

## Build and Run

```bash
# Build
mvn clean package

# Run
mvn spring-boot:run

# Run tests
mvn test

# API available at: http://localhost:8080
```

## Security Considerations

- **Input Validation**: Use Bean Validation (@Valid, @NotBlank, @Size)
- **No Authentication**: Out of scope for test project
- **SQL Injection**: Protected by JPA/Hibernate
- **Error Messages**: Don't expose internal details via GlobalExceptionHandler

## SpecBuddy Testing Criteria

This project succeeds as a SpecBuddy test if:

✅ **Workflow Completeness**
- [ ] Specification created successfully
- [ ] Implementation plan generated with numbered step headings
- [ ] All steps executable via `/spec-buddy:execute`

✅ **Step Execution**
- [ ] Setup steps (Maven project init, dependencies) work
- [ ] Code creation steps (entities, DTOs, controllers) work
- [ ] Testing steps work
- [ ] Documentation steps work

✅ **Reference Validation**
- [ ] Run commands (mvn commands) execute correctly
- [ ] File references are clear and helpful
- [ ] Step boundaries (### headings) work correctly
- [ ] Spec references in plan's References section resolve properly

✅ **Agent Behavior**
- [ ] Agent executes only assigned step
- [ ] Agent validates success criteria
- [ ] Agent provides clear completion reports
- [ ] Agent handles Java code correctly

✅ **Final Outcome**
- [ ] Working Spring Boot API
- [ ] All endpoints functional
- [ ] Tests pass
- [ ] Documentation complete
- [ ] Process issues documented

## Open Questions

1. **Project initialization**: Use Spring Initializr or create pom.xml manually?
   - Decision: Manual pom.xml to test file creation capabilities

2. **Testing depth**: Unit tests only or include integration tests?
   - Decision: Both to test different step types

3. **Database**: H2 in-memory or simple in-memory repository?
   - Decision: H2 with JPA for realistic Spring Boot experience

## Future Enhancements

After SpecBuddy validation:
- PostgreSQL database (Phase 2)
- Spring Security authentication (Phase 2)
- API documentation with Swagger/OpenAPI (Phase 2)
- Docker containerization (Phase 3)

## References

- Spring Boot documentation: https://spring.io/projects/spring-boot
- Spring Data JPA: https://spring.io/projects/spring-data-jpa
- Bean Validation: https://beanvalidation.org/
- SpecBuddy concept: `.specs/concept.md`

## Success Criteria for This Specification

This specification is successful if:
- [x] Clear enough to generate an implementation plan
- [ ] Contains all information needed for Spring Boot implementation
- [ ] Testable requirements with acceptance criteria
- [ ] Realistic scope for a test project
- [ ] Exercises key SpecBuddy features with Java/Spring ecosystem

---

**Next Steps:**
1. Review this specification
2. Create implementation plan: `.specs/plans/implement-task-api.md`
3. Execute plan step-by-step with `/spec-buddy:execute`
4. Document findings and improvements for SpecBuddy
