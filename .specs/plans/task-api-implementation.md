# Implementation Plan: Spring Boot Task API

**Status:** Draft
**Created:** 2026-02-12
**Estimated Effort:** 6-8 hours
**Dependencies:** Java 17+, Maven 3.6+
**Project Location:** `.test/` subdirectory

## Overview

Implement a complete Spring Boot REST API for task management with full CRUD operations, JPA persistence, validation, comprehensive testing, and documentation. This project will be created in the `.test/` subdirectory and serves as a test case for validating the SpecBuddy workflow with Java/Spring Boot ecosystem.

## Goals

- Build a functional RESTful Task API following Spring Boot best practices
- Implement layered architecture: Controller → Service → Repository
- Include comprehensive unit and integration tests
- Validate SpecBuddy's step-by-step execution workflow
- Test all marker types (@file:, @cmd:, @range:, @step:) in Java context

## Scope

**In Scope:**
- Complete Spring Boot project structure with Maven
- Task entity with JPA annotations and H2 database
- All 5 REST endpoints (Create, List, Get, Update, Delete)
- Request/response DTOs with Bean Validation
- Service layer with business logic
- JPA repository for data access
- Exception handling with @ControllerAdvice
- Unit tests for service layer (Mockito)
- Integration tests for REST endpoints (MockMvc)
- README with API documentation and usage examples
- Application configuration for H2 and JPA

**Out of Scope:**
- Frontend implementation or UI
- Authentication/authorization (Spring Security)
- External database (PostgreSQL, MySQL)
- Docker containerization
- Cloud deployment configuration
- Swagger/OpenAPI documentation (future enhancement)
- Advanced query features (pagination, sorting)

## Prerequisites

- [ ] Java 17 or higher installed (`java --version`)
- [ ] Maven 3.6+ installed (`mvn --version`)
- [ ] IDE or text editor configured for Java development
- [ ] Port 8080 available for local server
- [ ] Git initialized in project directory (optional but recommended)

## Implementation Steps

@step:start initialize-project-structure
### Step 1: Initialize Maven Project Structure

Create the complete Maven project directory structure following Spring Boot conventions in the `.test/` subdirectory and initialize the pom.xml with all required dependencies.

**Context:**
- @spec:.specs/test-project-task-api.md (reference specification)
- New Spring Boot 3.2+ project with Java 17
- Maven-based build system
- Project location: `.test/` subdirectory

**Actions:**
1. Create .test directory and complete Maven directory structure:
   - @cmd:mkdir -p .test/src/main/java/com/example/taskapi/{controller,service,repository,model,dto,exception}
   - @cmd:mkdir -p .test/src/main/resources
   - @cmd:mkdir -p .test/src/test/java/com/example/taskapi/{controller,service}
2. Create @file:.test/pom.xml with Spring Boot 3.2.2, dependencies:
   - spring-boot-starter-web (REST)
   - spring-boot-starter-data-jpa (JPA/Hibernate)
   - spring-boot-starter-validation (Bean Validation)
   - h2 (in-memory database)
   - lombok (reduce boilerplate)
   - spring-boot-starter-test (JUnit 5, Mockito, MockMvc)
3. Create @file:.test/src/main/java/com/example/taskapi/TaskApiApplication.java (main class)
4. Verify structure: @cmd:find .test/src -type d

**Success Criteria:**
- [ ] Directory .test/ exists with Spring Boot project structure
- [ ] File .test/pom.xml exists with all required dependencies
- [ ] TaskApiApplication.java exists in .test/src/main/java with @SpringBootApplication annotation
- [ ] Maven can resolve dependencies: `cd .test && mvn dependency:resolve` completes successfully
- [ ] Project builds without errors: `cd .test && mvn clean compile` succeeds

**Dependencies:** none
**Estimated Time:** 15 minutes
@step:end

@step:start create-task-entity-and-enum
### Step 2: Create Task Entity and TaskStatus Enum

Implement the core Task entity with JPA annotations and the TaskStatus enum following the specification data model.

**Context:**
- @spec:.specs/test-project-task-api.md#L205-L235 (data model reference)
- @file:.test/pom.xml (verify JPA and Lombok dependencies)

**Actions:**
1. Create @file:.test/src/main/java/com/example/taskapi/model/TaskStatus.java:
   - Enum with values: TODO, IN_PROGRESS, DONE
2. Create @file:.test/src/main/java/com/example/taskapi/model/Task.java:
   - JPA annotations: @Entity, @Table(name = "tasks")
   - Fields: id (Long), title (String), description (String), status (TaskStatus), createdAt, updatedAt
   - @Id with @GeneratedValue(strategy = IDENTITY)
   - @Column annotations with constraints (title: 200 chars, description: 1000 chars)
   - @Enumerated(EnumType.STRING) for status
   - @CreatedDate and @LastModifiedDate for timestamps
   - Lombok annotations: @Data, @NoArgsConstructor, @AllArgsConstructor
   - Add @EntityListeners(AuditingEntityListener.class) for timestamp management
3. Verify compilation: @cmd:cd .test && mvn compile

**Success Criteria:**
- [ ] TaskStatus.java exists in .test/src/main/java with three enum values (TODO, IN_PROGRESS, DONE)
- [ ] Task.java exists in .test/src/main/java with all required fields and JPA annotations
- [ ] Task entity compiles without errors
- [ ] Lombok generates getters/setters/constructors (verify in IDE or compilation logs)
- [ ] JPA annotations are correct (verified by successful compilation)

**Dependencies:** initialize-project-structure
**Estimated Time:** 20 minutes
@step:end

@step:start create-dto-classes
### Step 3: Create DTO Classes for Requests and Responses

Implement Data Transfer Objects (DTOs) for API requests and responses with Bean Validation annotations.

**Context:**
- @spec:.specs/test-project-task-api.md#L247-L279 (DTO specifications)
- @file:.test/src/main/java/com/example/taskapi/model/Task.java (entity reference)
- @file:.test/src/main/java/com/example/taskapi/model/TaskStatus.java (enum reference)

**Actions:**
1. Create @file:.test/src/main/java/com/example/taskapi/dto/TaskCreateRequest.java:
   - Fields: title (String), description (String)
   - Validation: @NotBlank and @Size(min=1, max=200) on title
   - Validation: @Size(max=1000) on description
   - Lombok: @Data, @NoArgsConstructor, @AllArgsConstructor
2. Create @file:.test/src/main/java/com/example/taskapi/dto/TaskUpdateRequest.java:
   - Fields: title (String), description (String), status (TaskStatus)
   - Validation: @Size(min=1, max=200) on title (optional field)
   - Validation: @Size(max=1000) on description (optional field)
   - Lombok: @Data, @NoArgsConstructor, @AllArgsConstructor
3. Create @file:.test/src/main/java/com/example/taskapi/dto/TaskResponse.java:
   - Fields: id, title, description, status, createdAt, updatedAt
   - Lombok: @Data, @NoArgsConstructor, @AllArgsConstructor
   - Add constructor that takes Task entity and maps fields
4. Verify compilation: @cmd:cd .test && mvn compile

**Success Criteria:**
- [ ] TaskCreateRequest.java exists in .test/src/main/java with validation annotations
- [ ] TaskUpdateRequest.java exists in .test/src/main/java with optional fields and validation
- [ ] TaskResponse.java exists in .test/src/main/java with constructor mapping from Task entity
- [ ] All DTOs compile without errors
- [ ] Validation annotations are correctly applied (verified by compilation)

**Dependencies:** create-task-entity-and-enum
**Estimated Time:** 20 minutes
@step:end

@step:start create-repository-interface
### Step 4: Create JPA Repository Interface

Implement the Spring Data JPA repository interface for Task entity with custom query methods.

**Context:**
- @file:.test/src/main/java/com/example/taskapi/model/Task.java (entity)
- @file:.test/src/main/java/com/example/taskapi/model/TaskStatus.java (enum for filtering)
- Spring Data JPA repository pattern

**Actions:**
1. Create @file:.test/src/main/java/com/example/taskapi/repository/TaskRepository.java:
   - Interface extending JpaRepository<Task, Long>
   - Annotation: @Repository
   - Custom query method: `List<Task> findByStatus(TaskStatus status);`
   - Inherits CRUD methods: save(), findById(), findAll(), deleteById()
2. Verify compilation: @cmd:cd .test && mvn compile

**Success Criteria:**
- [ ] TaskRepository.java exists in .test/src/main/java and extends JpaRepository<Task, Long>
- [ ] @Repository annotation is present
- [ ] Custom findByStatus method is defined
- [ ] Interface compiles without errors
- [ ] Spring Data JPA will auto-implement the interface (verified by project structure)

**Dependencies:** create-task-entity-and-enum
**Estimated Time:** 10 minutes
@step:end

@step:start create-custom-exception
### Step 5: Create Custom Exception and Global Exception Handler

Implement TaskNotFoundException and GlobalExceptionHandler for consistent error responses across the API.

**Context:**
- @spec:.specs/test-project-task-api.md#L282-L303 (error response format)
- @file:.test/pom.xml (verify spring-boot-starter-web dependency)

**Actions:**
1. Create @file:.test/src/main/java/com/example/taskapi/exception/TaskNotFoundException.java:
   - Extends RuntimeException
   - Constructor: TaskNotFoundException(Long id) with message format "Task not found with id: {id}"
2. Create @file:.test/src/main/java/com/example/taskapi/exception/GlobalExceptionHandler.java:
   - Annotation: @ControllerAdvice
   - Method handleTaskNotFound: @ExceptionHandler(TaskNotFoundException.class), returns 404
   - Method handleValidation: @ExceptionHandler(MethodArgumentNotValidException.class), returns 400
   - Method handleGeneral: @ExceptionHandler(Exception.class), returns 500
   - Error response format: timestamp, status, error, message, errors (for validation)
   - Use @ResponseStatus or ResponseEntity for proper status codes
3. Verify compilation: @cmd:cd .test && mvn compile

**Success Criteria:**
- [ ] TaskNotFoundException.java exists in .test/src/main/java and extends RuntimeException
- [ ] GlobalExceptionHandler.java exists in .test/src/main/java with @ControllerAdvice annotation
- [ ] Handler methods for 404, 400, and 500 errors are implemented
- [ ] Error response structure matches specification
- [ ] Both files compile without errors

**Dependencies:** initialize-project-structure
**Estimated Time:** 20 minutes
@step:end

@step:start create-service-layer
### Step 6: Create Service Interface and Implementation

Implement the service layer with business logic for all task operations following the service interface pattern.

**Context:**
- @file:.test/src/main/java/com/example/taskapi/model/Task.java (entity)
- @file:.test/src/main/java/com/example/taskapi/repository/TaskRepository.java (repository)
- @file:.test/src/main/java/com/example/taskapi/dto/TaskCreateRequest.java (create DTO)
- @file:.test/src/main/java/com/example/taskapi/dto/TaskUpdateRequest.java (update DTO)
- @file:.test/src/main/java/com/example/taskapi/dto/TaskResponse.java (response DTO)
- @file:.test/src/main/java/com/example/taskapi/exception/TaskNotFoundException.java (exception)

**Actions:**
1. Create @file:.test/src/main/java/com/example/taskapi/service/TaskService.java:
   - Interface defining methods:
     - TaskResponse createTask(TaskCreateRequest request)
     - List<TaskResponse> getAllTasks()
     - List<TaskResponse> getTasksByStatus(TaskStatus status)
     - TaskResponse getTaskById(Long id)
     - TaskResponse updateTask(Long id, TaskUpdateRequest request)
     - void deleteTask(Long id)
2. Create @file:.test/src/main/java/com/example/taskapi/service/TaskServiceImpl.java:
   - Annotation: @Service
   - Inject TaskRepository via constructor
   - Implement all interface methods
   - createTask: map DTO to Task entity, set status=TODO, save, return TaskResponse
   - getAllTasks: fetch all, map to TaskResponse list
   - getTasksByStatus: use repository.findByStatus(), map to TaskResponse list
   - getTaskById: findById or throw TaskNotFoundException
   - updateTask: fetch task, update non-null fields, save, return TaskResponse
   - deleteTask: verify exists (throw if not), then delete
3. Verify compilation: @cmd:cd .test && mvn compile

**Success Criteria:**
- [ ] TaskService.java interface exists in .test/src/main/java with all 6 method signatures
- [ ] TaskServiceImpl.java exists in .test/src/main/java with @Service annotation
- [ ] All methods are implemented with correct business logic
- [ ] TaskNotFoundException is thrown when tasks are not found
- [ ] DTOs are correctly mapped to/from entities
- [ ] Service layer compiles without errors

**Dependencies:** create-task-entity-and-enum, create-dto-classes, create-repository-interface, create-custom-exception
**Estimated Time:** 30 minutes
@step:end

@step:start create-rest-controller
### Step 7: Create REST Controller with All Endpoints

Implement the TaskController with all REST endpoints following Spring Boot conventions and the API specification.

**Context:**
- @spec:.specs/test-project-task-api.md#L237-L246 (API endpoints table)
- @file:.test/src/main/java/com/example/taskapi/service/TaskService.java (service interface)
- @file:.test/src/main/java/com/example/taskapi/dto/TaskCreateRequest.java (create DTO)
- @file:.test/src/main/java/com/example/taskapi/dto/TaskUpdateRequest.java (update DTO)
- @file:.test/src/main/java/com/example/taskapi/dto/TaskResponse.java (response DTO)
- @file:.test/src/main/java/com/example/taskapi/model/TaskStatus.java (enum for filtering)

**Actions:**
1. Create @file:.test/src/main/java/com/example/taskapi/controller/TaskController.java:
   - Annotations: @RestController, @RequestMapping("/api/tasks")
   - Inject TaskService via constructor
   - POST /api/tasks: createTask(@Valid @RequestBody TaskCreateRequest) → 201 Created
   - GET /api/tasks: getAllTasks(@RequestParam Optional<TaskStatus> status) → 200 OK
   - GET /api/tasks/{id}: getTaskById(@PathVariable Long id) → 200 OK
   - PUT /api/tasks/{id}: updateTask(@PathVariable Long id, @Valid @RequestBody TaskUpdateRequest) → 200 OK
   - DELETE /api/tasks/{id}: deleteTask(@PathVariable Long id) → 204 No Content
   - Use @ResponseStatus annotations for proper status codes
   - Use @Valid for request body validation
2. Verify compilation: @cmd:cd .test && mvn compile

**Success Criteria:**
- [ ] TaskController.java exists in .test/src/main/java with @RestController and @RequestMapping annotations
- [ ] All 5 endpoints are implemented (POST, GET list, GET by id, PUT, DELETE)
- [ ] HTTP methods and paths match specification exactly
- [ ] Request validation is enabled with @Valid annotations
- [ ] Response status codes are correct (201, 200, 204)
- [ ] Optional status query parameter is handled in list endpoint
- [ ] Controller compiles without errors

**Dependencies:** create-service-layer, create-dto-classes
**Estimated Time:** 25 minutes
@step:end

@step:start configure-application-properties
### Step 8: Configure Application Properties

Create application configuration for H2 database, JPA settings, and enable JPA auditing for timestamps.

**Context:**
- @file:.test/src/main/java/com/example/taskapi/model/Task.java (entity with @CreatedDate/@LastModifiedDate)
- @file:.test/src/main/java/com/example/taskapi/TaskApiApplication.java (main class)
- H2 in-memory database for development and testing

**Actions:**
1. Create @file:.test/src/main/resources/application.properties:
   - H2 configuration: spring.datasource.url=jdbc:h2:mem:taskdb
   - H2 console: spring.h2.console.enabled=true, path=/h2-console
   - JPA configuration: spring.jpa.hibernate.ddl-auto=create-drop
   - JPA show SQL: spring.jpa.show-sql=true (for debugging)
   - Server port: server.port=8080
2. Modify @range:.test/src/main/java/com/example/taskapi/TaskApiApplication.java#L1-L10:
   - Add @EnableJpaAuditing annotation to enable @CreatedDate/@LastModifiedDate
3. Verify configuration: @cmd:cd .test && mvn spring-boot:run (should start without errors, then stop with Ctrl+C)

**Success Criteria:**
- [ ] application.properties exists in .test/src/main/resources with H2 and JPA configuration
- [ ] TaskApiApplication.java in .test/src/main/java has @EnableJpaAuditing annotation
- [ ] Application starts successfully: `cd .test && mvn spring-boot:run` shows "Started TaskApiApplication"
- [ ] H2 console is accessible at http://localhost:8080/h2-console (verify in logs)
- [ ] No errors in startup logs related to database or JPA configuration

**Dependencies:** initialize-project-structure, create-task-entity-and-enum
**Estimated Time:** 15 minutes
@step:end

@step:start create-service-unit-tests
### Step 9: Create Unit Tests for Service Layer

Implement comprehensive unit tests for TaskServiceImpl using JUnit 5 and Mockito.

**Context:**
- @spec:.specs/test-project-task-api.md#L350-L365 (unit test structure)
- @file:.test/src/main/java/com/example/taskapi/service/TaskServiceImpl.java (service implementation)
- @file:.test/src/main/java/com/example/taskapi/repository/TaskRepository.java (mocked repository)

**Actions:**
1. Create @file:.test/src/test/java/com/example/taskapi/service/TaskServiceTest.java:
   - Annotations: @ExtendWith(MockitoExtension.class)
   - @Mock TaskRepository repository
   - @InjectMocks TaskServiceImpl service
   - Test createTask_ValidInput_ReturnsTask:
     - Mock repository.save() to return Task entity
     - Call service.createTask()
     - Verify TaskResponse is returned with correct data
   - Test getTaskById_ExistingId_ReturnsTask:
     - Mock repository.findById() to return Optional<Task>
     - Verify TaskResponse is returned
   - Test getTaskById_NonExistingId_ThrowsException:
     - Mock repository.findById() to return Optional.empty()
     - Verify TaskNotFoundException is thrown
   - Test updateTask_ValidInput_UpdatesAndReturns:
     - Mock repository.findById() and save()
     - Verify fields are updated correctly
   - Test deleteTask_ExistingId_DeletesTask:
     - Mock repository.findById() and deleteById()
     - Verify repository.deleteById() is called
   - Test getAllTasks_ReturnsAllTasks:
     - Mock repository.findAll()
     - Verify list of TaskResponse is returned
2. Run tests: @cmd:cd .test && mvn test -Dtest=TaskServiceTest

**Success Criteria:**
- [ ] TaskServiceTest.java exists in .test/src/test/java with all 6 test methods
- [ ] Tests use Mockito to mock repository dependencies
- [ ] All test methods follow AAA pattern (Arrange, Act, Assert)
- [ ] Tests verify both success and failure scenarios
- [ ] All tests pass: `cd .test && mvn test -Dtest=TaskServiceTest` shows BUILD SUCCESS
- [ ] Test coverage includes exception scenarios (TaskNotFoundException)

**Dependencies:** create-service-layer
**Estimated Time:** 35 minutes
@step:end

@step:start create-controller-integration-tests
### Step 10: Create Integration Tests for REST Controller

Implement integration tests for TaskController using Spring Boot Test and MockMvc.

**Context:**
- @spec:.specs/test-project-task-api.md#L367-L412 (integration test structure and test cases)
- @file:.test/src/main/java/com/example/taskapi/controller/TaskController.java (controller)
- @file:.test/src/main/resources/application.properties (test will use H2 database)

**Actions:**
1. Create @file:.test/src/test/java/com/example/taskapi/controller/TaskControllerTest.java:
   - Annotations: @SpringBootTest, @AutoConfigureMockMvc
   - @Autowired MockMvc mockMvc
   - @Autowired TaskRepository repository (for test data setup)
   - @BeforeEach: clear repository before each test
   - Test createTask_ValidInput_Returns201:
     - POST /api/tasks with valid JSON
     - Expect status 201, verify response contains id, title, status=TODO
   - Test createTask_InvalidInput_Returns400:
     - POST /api/tasks with missing title
     - Expect status 400 with validation errors
   - Test getAllTasks_ReturnsAllTasks:
     - Create 2 test tasks in repository
     - GET /api/tasks
     - Expect status 200, verify array with 2 tasks
   - Test getAllTasks_FilterByStatus_ReturnsFiltered:
     - Create tasks with different statuses
     - GET /api/tasks?status=TODO
     - Verify only TODO tasks returned
   - Test getTaskById_ExistingId_Returns200:
     - Create test task
     - GET /api/tasks/{id}
     - Expect status 200, verify task data
   - Test getTaskById_NonExistingId_Returns404:
     - GET /api/tasks/999
     - Expect status 404
   - Test updateTask_ValidInput_Returns200:
     - Create test task
     - PUT /api/tasks/{id} with status=DONE
     - Expect status 200, verify status updated
   - Test deleteTask_ExistingId_Returns204:
     - Create test task
     - DELETE /api/tasks/{id}
     - Expect status 204, verify task no longer exists
2. Run tests: @cmd:cd .test && mvn test -Dtest=TaskControllerTest

**Success Criteria:**
- [ ] TaskControllerTest.java exists in .test/src/test/java with all 8 test methods covering all test cases
- [ ] Tests use MockMvc to perform HTTP requests
- [ ] Tests verify request bodies, status codes, and response content
- [ ] Tests cover success and error scenarios (404, 400)
- [ ] All tests pass: `cd .test && mvn test -Dtest=TaskControllerTest` shows BUILD SUCCESS
- [ ] Tests validate JSON request/response format

**Dependencies:** create-rest-controller, configure-application-properties
**Estimated Time:** 45 minutes
@step:end

@step:start create-readme-documentation
### Step 11: Create README with API Documentation

Create comprehensive README documentation with API endpoints, examples, and instructions for building and running the application.

**Context:**
- @spec:.specs/test-project-task-api.md#L305-L329 (example usage)
- @spec:.specs/test-project-task-api.md#L413-L426 (build and run commands)
- @file:.test/pom.xml (project dependencies)
- @file:.test/src/main/java/com/example/taskapi/controller/TaskController.java (endpoints)

**Actions:**
1. Create @file:.test/README.md with sections:
   - Project title and overview (Spring Boot Task API)
   - Technology stack (Spring Boot 3.2, Java 17, H2, Maven)
   - Prerequisites (Java, Maven)
   - Build instructions: `mvn clean package`
   - Run instructions: `mvn spring-boot:run`
   - Test instructions: `mvn test`
   - API endpoints table with all 5 endpoints
   - Request/response examples for each endpoint (curl commands)
   - Example: Create task, List tasks, Get task, Update task, Delete task
   - H2 console access information
   - Project structure overview
   - Future enhancements section
2. Verify documentation accuracy by comparing with actual implementation

**Success Criteria:**
- [ ] README.md exists in .test/ directory
- [ ] All API endpoints are documented with correct HTTP methods and paths
- [ ] curl examples are provided for each endpoint
- [ ] Build, run, and test instructions are clear and accurate
- [ ] Example requests and responses match DTO structures
- [ ] H2 console access URL and credentials are documented
- [ ] README is well-formatted with proper markdown syntax

**Dependencies:** create-rest-controller, configure-application-properties
**Estimated Time:** 30 minutes
@step:end

@step:start run-all-tests-and-validate
### Step 12: Run Complete Test Suite and Validate Application

Execute all tests, start the application, and perform end-to-end validation of all API endpoints.

**Context:**
- @file:.test/src/test/java/com/example/taskapi/service/TaskServiceTest.java (unit tests)
- @file:.test/src/test/java/com/example/taskapi/controller/TaskControllerTest.java (integration tests)
- @file:.test/README.md (API documentation with examples)

**Actions:**
1. Run complete test suite: @cmd:cd .test && mvn clean test
2. Build application: @cmd:cd .test && mvn clean package
3. Start application: @cmd:cd .test && mvn spring-boot:run (run in background or separate terminal)
4. Manual validation (using curl or tools like Postman):
   - Create task: POST /api/tasks with valid data
   - List all tasks: GET /api/tasks
   - Get task by ID: GET /api/tasks/{id}
   - Update task: PUT /api/tasks/{id}
   - Filter by status: GET /api/tasks?status=TODO
   - Delete task: DELETE /api/tasks/{id}
   - Test error cases: invalid data (400), non-existent ID (404)
5. Access H2 console: http://localhost:8080/h2-console
6. Stop application

**Success Criteria:**
- [ ] All unit tests pass: TaskServiceTest shows 6/6 passed
- [ ] All integration tests pass: TaskControllerTest shows 8/8 passed
- [ ] Maven build completes successfully: `cd .test && mvn clean package` shows BUILD SUCCESS
- [ ] Application starts without errors and listens on port 8080
- [ ] All 5 API endpoints respond correctly with expected status codes
- [ ] Error handling works correctly (404 for missing tasks, 400 for validation)
- [ ] H2 console is accessible and shows tasks table
- [ ] Manual testing with curl commands from README works as documented

**Dependencies:** create-service-unit-tests, create-controller-integration-tests, create-readme-documentation
**Estimated Time:** 30 minutes
@step:end

## Validation Checklist

- [ ] All referenced files exist or are created by the plan
- [ ] All Maven commands are valid and appropriate for Spring Boot
- [ ] Step dependencies form a valid directed acyclic graph (no circular dependencies)
- [ ] Success criteria are specific and measurable for each step
- [ ] Each step has clear acceptance criteria (3-6 checkboxes)
- [ ] File paths follow Spring Boot conventions (src/main/java, src/test/java)
- [ ] JPA, validation, and Spring annotations are correctly specified
- [ ] Test coverage includes both unit tests (Mockito) and integration tests (MockMvc)

## Risks and Mitigations

- **Risk:** Java/Maven version incompatibility
  - *Mitigation:* Verify Java 17+ and Maven 3.6+ installed before starting. Use `java --version` and `mvn --version` to confirm.

- **Risk:** Port 8080 already in use
  - *Mitigation:* Check for processes using port 8080 before starting application. Change port in application.properties if needed.

- **Risk:** JPA auditing (@CreatedDate/@LastModifiedDate) not working
  - *Mitigation:* Ensure @EnableJpaAuditing is added to main application class. Verify AuditingEntityListener is applied to Task entity.

- **Risk:** H2 console not accessible
  - *Mitigation:* Verify spring.h2.console.enabled=true in application.properties. Check application startup logs for H2 console URL.

- **Risk:** Tests fail due to database state
  - *Mitigation:* Use @BeforeEach in integration tests to clear repository before each test. Use H2 in-memory database which resets on restart.

- **Risk:** Validation annotations not working
  - *Mitigation:* Ensure spring-boot-starter-validation dependency is in pom.xml. Verify @Valid annotation is used in controller methods.

## Rollback Plan

If implementation fails at any step:

1. **Before Step 6 (Service Layer)**: Delete project directory and start fresh, as only structure and simple classes exist
2. **After Step 6**: Use git to revert to previous working commit (if git initialized)
3. **After Step 9-10 (Tests)**: Comment out failing tests, fix issues incrementally
4. **Step 12 (Validation)**: Application can still run even if some tests fail - fix tests individually

**Complete rollback:**
1. Stop running application (Ctrl+C or kill process on port 8080)
2. Delete entire .test/ directory: `rm -rf .test`
3. Start over from Step 1 with lessons learned from failures

## References

- @spec:.specs/test-project-task-api.md (source specification)
- Spring Boot Documentation: https://spring.io/projects/spring-boot
- Spring Data JPA: https://spring.io/projects/spring-data-jpa
- Bean Validation (JSR-380): https://beanvalidation.org/2.0/
- JUnit 5 User Guide: https://junit.org/junit5/docs/current/user-guide/
- Mockito Documentation: https://javadoc.io/doc/org.mockito/mockito-core/latest/org/mockito/Mockito.html

---

**Next Steps:**

To begin implementation, execute the first step:

```
/spec-buddy:execute .specs/plans/task-api-implementation.md initialize-project-structure
```

After each step completes, proceed to the next step in sequence. The plan is designed to build incrementally, with each step depending on previous steps being complete.

**Validation Notes:**

This plan tests SpecBuddy's capabilities with:
- Java/Spring Boot ecosystem (different from typical Node.js examples)
- Maven commands (@cmd:mvn ...)
- Complex Spring Boot project structure
- JPA/Hibernate configuration
- Both unit and integration testing approaches
- Multi-package Java project organization

Review the plan and adjust as needed before execution.